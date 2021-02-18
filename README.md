# Database Serverless

![Build Status](https://travis-ci.org/joemccann/dillinger.svg?branch=master)

This is a database structure template, this project includes the following features.

  - Creation of the database structure in AWS RDS automatically (infrastructure folder).
  - Use of PrismA ORM to work with data schema and no longer SQL.

# Commands Prisma

Client

```sh
$ npm install @prisma/client@2.14.0
```

Debug

```sh
$ export DEBUG="*" 
```

Setup a new Prisma project

```sh
$ npm run prisma:init 
```

Introspect an existing database

```sh
$ npm run prisma:introspect
```

Generate artifacts (e.g. Prisma Client)

```sh
$ npm run prisma:generate
```

Create draft migrations from your Prisma schema, apply them to the database, generate artifacts (e.g. Prisma Client) - draft - with Specify a schema

```sh
$ npm run prisma:migrate-dev-create-only
```

Create migrations from your Prisma schema, apply them to the database, generate artifacts (e.g. Prisma Client) - apply direct - with Specify a schema

```sh
Migrate Usage

  $ prisma migrate [command] [options] --preview-feature

Commands for development
		 dev   Create a migration from changes in Prisma schema, apply it to the database
			   trigger generators (e.g. Prisma Client)
	   reset   Reset your database and apply all migrations, all data will be lost

Commands for production/staging

	  deploy   Apply pending migrations to the database
	  status   Check the status of your database migrations
	 resolve   Resolve issues with database migrations, i.e. baseline, failed migration, hotfix

$ npm run prisma:migrate-dev
$ npm run prisma:migrate-deploy
$ npm run prisma:migrate-status
$ npm run prisma:migrate-reset

```

Browse your data

```sh
$ npm run prisma:studio
```

Show path binaries

```sh
$ npm run prisma:version
```

Prisma helps app developers build faster and make fewer errors with an open source ORM for PostgreSQL, MySQL and SQLite.  For more information a ccess the website of [Prisma][Prisma] or [Documentation][prisma-doc]


### Tech

Architectures used:

* [AWS] - Computing Cloud AWS!
* [Serverless] - Serverless framework
* [Prisma] - ORM Database
* [GitLab] - DevOps Platform
* [Node.js] - Evented I/O for the backend








   [Serverless]: <https://www.serverless.com/>
   [AWS]: <https://aws.amazon.com/pt/>
   [prisma-doc]: <https://www.prisma.io/docs/getting-started/quickstart-typescript>
   [Prisma]: <https://www.prisma.io/>
   [Node.js]: <http://nodejs.org>
   [GitLab]: <https://gitlab.com/gitlab-org/gitlab>
