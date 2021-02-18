'use strict'

const passwordGenerator = require('generate-password')

class creationDBUser {
  constructor(serverless, options) {
    this.initialized = false
    this.serverless = serverless
    this.options = options
    this.naming = this.serverless.providers.aws.naming
    this.parametersAdded = []
    this.hooks = {
      'after:package:setupProviderConfiguration': this.setupProviderConfiguration.bind(this),
      'after:aws:deploy:finalize:cleanup': this.finalizeCleanup.bind(this),
    }
  }

  initializeVariables() {
    if (!this.initialized) {
      const awsCreds = Object.assign({}, this.serverless.providers.aws.getCredentials(), { region: this.serverless.service.provider.region })
      this.ssm = new this.serverless.providers.aws.sdk.SSM(awsCreds)
      this.rds = new this.serverless.providers.aws.sdk.RDS(awsCreds)

      this.initialized = true
    }
  }

  async setupProviderConfiguration(){
    this.initializeVariables()
    const resources = this.serverless.service.resources.Resources

    const dbClusters = Object.keys(resources).reduce((arr, key) => {
      if (resources[key].Type === 'AWS::RDS::DBCluster') {
        arr.push(resources[key])
      }
      return arr
    }, [])

    for(const dbCluster of dbClusters){

      const DBClusterIdentifier = dbCluster.Properties.DBClusterIdentifier
      const clusterIdentifier = this.naming.normalizePath(DBClusterIdentifier)

      const password = passwordGenerator.generate({
        length: 12,
        numbers: true,
        symbols: false,
        strict: true
      })

      dbCluster.DependsOn = [`${clusterIdentifier}Parameters`]
      dbCluster.Properties.MasterUsername = 'admin' // { 'Fn::GetAtt': [`${clusterIdentifier}MasterUsername`,'Value'] }
      dbCluster.Properties.MasterUserPassword = `${password}` // { 'Fn::GetAtt': [`${clusterIdentifier}MasterUserPassword`,'Value'] }

      const value = {
        clusterIdentifier: DBClusterIdentifier,
        username: 'admin',
        password: password,
      }

      const parameters = {
        [`${clusterIdentifier}Parameters`]: {
          Type: 'AWS::SSM::Parameter',
          Properties: {
            Name: `/${DBClusterIdentifier.replace('-', '/')}/PARAMETERS`,
            DataType: 'text',
            Type: 'String',
            Tier: 'Standard',
            Value: JSON.stringify({})
          }
        }
      }

      Object.assign(resources, parameters)
      this.parametersAdded.push({Name: `/${DBClusterIdentifier.replace('-', '/')}/PARAMETERS`, Value: value })
    }
  }

  async finalizeCleanup(){
    this.initializeVariables()

    for(const parameter of this.parametersAdded) {

      parameter.Type = 'SecureString'
      parameter.Overwrite = true
      parameter.Tier = 'Standard'

      const { DBClusters } = await this.rds.describeDBClusters({ DBClusterIdentifier: parameter.Value.clusterIdentifier }).promise()
      const info = DBClusters[0]

      const dialect = info.Engine.replace('aurora-','')

      parameter.Value = JSON.stringify({
        clusterIdentifier: parameter.Value.clusterIdentifier,
        endpoint: info.Endpoint,
        database: info.DatabaseName,
        username: info.MasterUsername,
        password: parameter.Value.password,
        dialect: dialect,
        bucketLog: `log-${parameter.Value.clusterIdentifier}`,
        port: `${info.Port}`,
        url: `${dialect}://${info.MasterUsername}:${parameter.Value.password}@${info.Endpoint}:${info.Port}/${info.DatabaseName}`
      })

      const response = await this.ssm.putParameter(parameter).promise()
      console.log(response)

    }
  }
}

module.exports = creationDBUser
