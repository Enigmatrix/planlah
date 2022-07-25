# planlah Developer Guide

![planlah](https://i.imgur.com/gFfSkI2.png)

## Introduction

planlah is an android application that will serve as a social media for Singaporeans to plan outings and get suggestions on places to go and food to eat.

### About this Developer Guide

This developer guide details how planlah is designed, implemented and tested.
Readers can find out more about the overall architecture of planlah, and also the implementation behind various functionalities. Technically inclined readers may wish to use the developer guide and further implement features or customise planlah for their own use!

### How to use the Developer Guide

The Developer Guide has been split into clear sections to allow readers to quickly navigate to their desired
information.

- You may navigate to any section from the [Table of contents](#table-of-contents).
- Click [here](#setting-up) for the Setting Up section and get started as a developer!
- Alternatively, if you wish to dive right into planlah's implementation,
  we would recommend starting in the [Design](#design) section.

<div style="page-break-after: always;"></div>

## Table of contents

- [planlah Developer Guide](#planlah-developer-guide)
  - [Introduction](#introduction)
    - [About this Developer Guide](#about-this-developer-guide)
    - [How to use the Developer Guide](#how-to-use-the-developer-guide)
  - [Table of contents](#table-of-contents)
  - [Setting Up](#setting-up)
    - [Backend](#backend)
    - [Frontend](#frontend)
  - [CI/CD Workflow](#cicd-workflow)
    - [Github Workflow](#github-workflow)
    - [Automated Checks](#automated-checks)
  - [Design](#design)
    - [Tech Stack](#tech-stack)
    - [Frontend and User Interface](#frontend-and-user-interface)
    - [Server](#server)
    - [Database](#database)
    - [Storage](#storage)
    - [Hosting](#hosting)
  - [Implementation](#implementation)
    - [Sign In and Token Authentication](#sign-in-and-token-authentication)
    - [Notifications and Subscription](#notifications-and-subscription)
    - [Recommender](#recommender)
    - [Outings](#outings)
      - [Outing Steps](#outing-steps)
      - [Voting](#voting)
      - [JobRunner](#jobrunner)
    - [Pagination](#pagination)
  - [Testing](#testing)
    - [Data Access Testing](#data-access-testing)
    - [Frontend Testing](#frontend-testing)
    - [Swagger (Expert Testing)](#swagger-expert-testing)
    - [Adminer (Expert Testing)](#adminer-expert-testing)
  - [Product scope](#product-scope)
    - [Target user profile:](#target-user-profile)
    - [Value proposition](#value-proposition)
    - [User Stories](#user-stories)
    - [Non-Functional Requirements](#non-functional-requirements)
  - [Glossary](#glossary)

<div style="page-break-after: always;"></div>

## Setting Up

You may follow this Setting Up guide and get started as a developer! This guide helps you import and set up the development environment for planlah onto GoLand / Android Studio,
but feel free to use your preferred IDE.

1. Ensure you have Go, Flutter, Python and Docker installed on your computer.
1. Fork the planlah repository from [here](https://github.com/Enigmatrix/planlah).
1. Clone your fork to your local machine, using the Git software you prefer.

### Backend

1. The backend directory in `/backend` can be opened in [GoLand](https://www.jetbrains.com/go/) 
1. Copy the `.env` file into the root directory of the clone (`.env` file is supplied only to project members)
1. Copy the Firebase Admin SDK credentials into the backend directory as well. Make sure the `GOOGLE_APPLICATION_CREDENTIALS` variable in the `.env` file points to this file.
1. Install swag by running `go install github.com/swaggo/swag/cmd/swag@latest`, then run `swag init` in the backend directory to generate Swagger documentation.
1. Install wire by running `go install github.com/google/wire/cmd/wire@latest`, then run `wire` in the backend directory to turn `deps.go` into a dependency injection tree.
1. Run the backend using `docker-compose up` in the root directory
  a. http://localhost:8080 is the backend
  b. http://localhost:8081 is the adminer, to easily interact with the database
  c. http://localhost:8080/swagger/index.html is the Swagger documentation page to test the backend code via API requests.



### Frontend

1. The mobile directory in `/mobile` can be opened with [Android Studio](https://developer.android.com/studio/install)
2. Run `flutter pub get` to fetch the Flutter dependencies
3. Launch a Android emulator instance (setup one using [this](https://developer.android.com/studio/run/emulator) if not done already)
4. Run `adb reverse tcp:8080 tcp:8080` to forward our backend's default port to the emulator
5. Run `adb reverse tcp:9000 tcp:9000` to forward our image storage service's default port to the emulator
6. Run the app using the Android Studio Run configuration.

If you are using multiple emulators (e.g. to test websockets), run Step 4 and 5 using the device specifier e.g. `adb -s emulator-5554 tcp:8080 tcp:8080`, where the specifier can be retreived using `adb devices`.

This developer guide does not provide detailed instructions on how to use planlah. For readers who wish to familiarise themselves with the commands of planlah, they can access the [User Guide]().

<div style="page-break-after: always;"></div>

## CI/CD Workflow

This section details the workflow that we have adopted for the continuous integration and deployment of our application.

### Github Workflow

The central repository that we perform continuous integration on is at the following [github repository](https://github.com/Enigmatrix/planlah). Our Github workflow is as follows:

1. Create an Issue on Github describing the bug/feature that you are trying to handle.
    a. Make use of the [TODO-list features](https://docs.github.com/en/issues/tracking-your-work-with-issues/about-task-lists) to breakdown the problem into multiple subproblems.
    b. Tag the required area into the issue e.g. `backend`
    c. Add it to the `Tracker` project and the current `Milestone` via the issue UI.
1. On the `Tracker` project, move the issue to `In Progress` when you want to work on it.
3. `git pull` the latest changes from the `main` branch of the repository to your local repository
4. Run `flutter pub get` in the `/mobile` directory
5. Create a new branch locally to implement new features or make changes to the codebase. Make sure it meets the naming convention (`feat/{name}` or `fix/{name}`)
6. Work on the changes, committing your code locally everytime a new feature or change has been implemented using the GoLand/ Android Studio VCS.
7. Rebase with `origin/main` frequently to avoid painful merge conflicts.
8. After all changes are made, `cd` into `/backend` and run `./test.sh`. Ensure that the test passes before proceeding to the next step.
1. To test the feature if it's in the backend, run `swag init` to regenerate the Swagger documentation, then visit the [Swagger documentation link](localhost:8080/swagger/index.html) to test API with queries.
9. Once the test passes, push the code from your local repository to the remote repository using `git push origin {branch name}`
10. Create a Pull request on Github, referencing the issue that describes the feature using closing keywords e.g. `fix #42`, where the issue is 42.
11. Another developer from the team will review your code, providing feedback if necessary
12. If no further updates are required for the pull request, and the required checks (`backend` and `mobile` CI/CD workflows) pass, the pull request can be merged into the `main` branch
13. Before starting on your next feature, run `git checkout main` to switch to the main branch locally. Run `git pull` to obtain the latest codebase. Repeat step 1

Bugs found in planlah are raised as an Issue on the GitHub Issue Tracker. This allows us to keep track of all bugs in a consolidated manner.

### Automated Checks

Currently, upon every Pull Request, two checks will be done automatically on Github:

1. `backend` check
1. `mobile` check

The `backend` check will see if the backend compiles, and all unit tests in the backend succeed to ensure that we do not accidentally break existing code. The `mobile` check tests if the flutter application compilies and can be built into valid output. These two checks *must* pass for the Pull Request to be merged.

## Design

This section describes the architectural and technical design of planlah, as well as the connections between them.
The whole tech stack of planlah is explained first, before diving into each component.

### Tech Stack

planlah is built using the follow technology:

**Flutter** <br />
![](https://cdn-images-1.medium.com/max/1200/1*5-aoK8IBmXve5whBQM90GA.png)
Flutter is an open-source framework by Google for building natively compiled, multi-platform applications from a single codebase. planlah uses Flutter for the frontend aspect of the program. Although planlah is primarily targetted for Android users, Flutter makes it easy to ship our application for iOS devices with minimal code changes. 

**Go** <br />
![](https://miro.medium.com/max/920/1*CdjOgfolLt_GNJYBzI-1QQ.jpeg)
The Go programming language is a statically typed, compiled programming language designed at Google. planlah uses Go, Gin (HTTP) and Gorm (Data Access / ORM) for the core of its backend. 

**Python** <br />
![](https://miro.medium.com/max/765/1*cyXCE-JcBelTyrK-58w6_Q.png)
Python is the most popular programming language for performing scientific computing thanks to NumPy. planlah uses Python, NumPy and Flask (HTTP interface) for its recommender interface. 

**Postgresql** <br />
![](https://upload.wikimedia.org/wikipedia/commons/2/29/Postgresql_elephant.svg)
PostgreSQL is the world's most advanced open source database. Postgis is a spatial database extender for PostgreSQL databases that adds support for geographic objects allowing location queries to be run in SQL. Since planlah's recommender filters for places in a 2km radius from the user's coordinates, Postgis was an excellent choice. 

**Firebase** <br />
![](https://i.imgur.com/XhYIdyE.png)

We only use Firebase for Authentication, specifically Google sign-in currently. This decision was made on the basis that it would be easy for us to add new auth providers such as Apple sign-in when we would port over to iOS.

**Minio** <br/>

![](https://i.imgur.com/Bh8AtvL.png)

Minio is an S3-compatible object storage solution to store files and other crucial data. We use it as a docker container that hosts the images for users, groups and posts.

### Frontend and User Interface

Please download a PlantUML renderer to view the class diagram for the planlah application as it is too large to paste as a png file here.

![UML File](planlah.puml)

Many of the components are made from sub-components taken from the Material-UI library. These components are made from Google's material design, with visuals and experiences that epitomizes modern web applications.

### Server

The server for planlah is implemented using a Gin as the HTTP routing framework. We have wrapped out own helpers around Gin to use the framework in a manner similar to the [Model-View-Controller](https://www.wikiwand.com/en/Model%E2%80%93view%E2%80%93controller) architecture. By defining controllers derived from a `BaseController` that registers endpoints, clients can communicate with the server.

Other than the obvious CRUD methods (wrappers over the Data Access Layer) to transfer data to and from the client, the server also has a JobRunner (to run code at specific times), a Websocket pub/sub mechanism (to keep the client updated about changes) as well as generated documentation for the HTTP methods using the Swagger Documentation link.

Use of the [Swagger Documentation link](http://localhost:8080/swagger/index.html) is recommended to test HTTP methods.

### Database

All data except for media (images are stored in minio) are stored on a Postgresql database. The Gorm package is used as an Data Access Layer / ORM to interact with this database in an Object-Oriented manner. The data model follows the data schema used by the server, with differences in casing to match the conventions of Postgresql and Go.

This diagram shows our data schema with connections shown explicitly, as an Entity Relationship Diagram:

![ERD](https://i.imgur.com/QnxeF0h.png)

### Storage

Images are stored using a `minio` docker container which only allows the `download` policy on files. We can upload files using the access keys in the .env file.

### Hosting

planlah is currently setup to run with docker-compose. Of course, it can run on plain docker (with minor configuration changes) and thus can also be deployed onto a Kubernetes cluster if necessary. To run the app with the current configuration, just run `docker-compose up`.

## Implementation

This subsection provides sequence and activity diagrams detailing the workflows for more complicated processes in planlah.

### Sign In and Token Authentication

This sequence diagrams shows the execution flow of the program when a user signs in to the app.

![](https://i.imgur.com/yF1SoKj.png)

Every time the user issues a request or tries to sign in, we can send an existing app token to the backend to pass in our authentication information. Else, we can create a new app token using our firebase token, then pass this on.

If the backend can verify the app token and check that it's not expired, the request is processed. Else, the mobile application must generate another app token. If this too fails, an unauthenticated error is passed on.

The mobile application tries the above 3 times until success if any unauthenticated error is present. This pertains to all HTTP requests made by the mobile application.

### Notifications and Subscription

Updates for specific dynamic changes like a new message, or new group member joining are made using our notification system. Essentially, it is a pubsub system made via Websockets.

On the backend side, a Websocket endpoint is present on the `ws://{HOST}/api/session/updates` path. Clients can connect to this (with their app token) using any websocket library of their choice to receive updates that pertain to them.

For example, the mobile application uses the `web_socket_channel` library to initiate a persistent websocket connection with the backend. This connection can receive various messages, which are in fact Discriminiated Unions (DUs) called `Update`s.

Currently we support a few `Update`s:
1. `MessageUpdate`: When a new message is sent
1. `GroupsUpdate`: When groups of a user are added/removed
1. `GroupUpdate`: When information of a group is modified
1. `PostUpdate`: When a new post from a friend arrives
1. `ActiveOutingUpdate`: When information about the active outing of a group changes
1. `FrientRequestUpdate`: When a new friend request arrives or it's status changes.

Our frontend then initializes a `SessionService` which is an encapsulation of the persistent websocket connection with the backend, which checks for updates pertaining to the relevant widget. For example, our `GroupChat` page would check for MessageUpdates and refresh the list of messages when an event subscription is received, rebuilding the widget accordingly. This helps to result in a responsive Widget as one would expect of a modern chat application, without repeatedly polling the server for the latest list of messages.  


### Recommender

Our recommender system is a simple Flask application that exposes a single endpoint: `Recommend`. When it is first initialized, the flask application calls the initDB function that checks if the `Places` table already exists, if so it does nothing. Else, it populates the database with data from our two .csv files while also converting the lat/long strings into Geography data types from PostGis. 

When our user clicks on the `Unsure?` button in the Create Outing Page, a request is made from the frontend to the backend. Our Gin server then makes a request to our Flask server's `Recommend` interface.

The `Recommend` interface takes in as parameters the user id, longitude, latitude and the place type which is either `Attraction` or `Restaurant`. It then obtains the user's feature vector for attractions or food depending on the place type parameter. A request is made to postgis to filter for places in a 2km radius from the user's lat/lon. 

We then use NumPy to vectorize the calculation of the cosine similarity between the user's profile vector and the profile vectors for the filtered places. For attractions, each dimension of the vector corresponds to a kind of activity that the user is interested in while each dimension of the food feature vector corresponds to a particular cuisine that the user may be interested in, such as Chinese or Mexican food. The vectors were normalized prior to database insertion. Since we employ NumPy's vectorization, this calculation is blazingly fast, compared to iteratively computing the cosine similarity between the user's profile vector and each row. the results are then sorted in descending order and the place ids for the top 5 results are returned to the backend. The backend converts these place ids to their corresponding `Place` models and returns it to the frontend where we display the results in a `ListView`.

### Outings

Outings are the crux of the planlah application and our groups and social posts features revolve around outings. An Outing has a start and end date as well as a vote deadline. This vote deadline is when the users must finish choosing which activities they want to go to.

#### Outing Steps
Outings are essentially a list of Outing steps, which are representative of individual activities. They are associated with a `Place` and specific start and end time range. Before the vote deadline of the outing, any number of outing steps can be added, even if they are conflicting with each other. 

![](https://i.imgur.com/j8OPw8K.jpg)


#### Voting 

To decide if the outing step is accepted into the final outing, users must vote for their favourite outing steps. After the vote deadline, those outings with insufficient votes will be dropped, and conflicts will be resolved in a FCFS (First Come First Serve) manner.

![](https://i.imgur.com/qd8dB8n.jpg)

#### JobRunner

The job runner maintains a list of tasks to run at specified times. It is similar to how cron works, except more powerful as it works cross-platform and only requires Postgresql. We currently use it to enqueue the outing step conflict resolution code at the specified vote deadline of an outing.

### Pagination

Most modern web applications such as Twitter, Facebook or Instagram employ the usage of pagination and lazy infinite lists to load the data (pictures, posts, comments ... etc) in batches instead of all at once. As the user scrolls through their feed, the next batch of data is then loaded to provide the feel of an "infinite scroll". This is done to avoid retrieving excessive amounts of data which is more efficient for the server as well as for the front end. 

As such, our backend constraints the `GET` interfaces such as GetMessages, GetPosts to only 10 items at a time with a `Page` parameter. Our frontend employs the use of the `InfiniteList` widget, when the user has scrolled through 50% of the existing items, the next batch of data is loaded. Our frontend also wraps the list in a `Refresh` widget that allows the user to swipe down to refresh his current feed, aligning with the expectations of modern social media applications.  


## Testing

The core of our testing is to test the business logic of the application. In our case, this is the form of the SQL queries in the Data Access Layer that are run to fetch and insert data into the database.

### Data Access Testing

To get as realistic as possible, we test against an actual Postgresql database with mock data, which runs inside an ephemeral docker container.

For the tests, we use the `testify` package along with it's Suites features to indicate per-test setup and teardown (recreate all mock data, destroy all mock data respectively). `testify` wraps Go's excellent Go `test` library and provides additional assertions and test helpers to make setting up unit tests easier.

In terms of the tests themselves, we test several scenarios that may occur: 

1. No rows in the database for the associated column
2. Invalid Parameters to the function
3. Trigger each possible error returned by the function

Our tests also run on the CI/CD offered by Github, and will fail the build on Github and block merging of the Pull Request if there are any errors:
![](https://i.imgur.com/Y9XypLT.png)
...
![](https://i.imgur.com/geHeFVR.png)

Currently, we have around 80 unit tests.


This form of integration testing ensures the interactions and functions between the server and database run as intended. These tests are run before each pull request to minimise code regression. Any changes that affect the interactions between the server and database can be quickly identified and fixed.

### Frontend Testing

The primary form of testing done for the frontend aspect of our application was through hands-on user testing as well as expert testing (testing done by developers)

For milestone 2's testing, we shared our apk with the other Orbital teams in our cluster. As most of them did not have android devices or means to run the apk with an Android emulator, we created a short 5 minute video where we held a walkthrough of the app on a Samsung Tab S8. After the video, some feedback we received regarded the username uniqueness validation being done earlier in the form, which we took to heart and implemented by milestone 3. 

For milestone 3's hands-on user testing, we invited our friends to download the release version apk and tell us their feedback regarding UI/UX and any potential sources of confusion regarding the application. We first sent our playtesters a link to our user guide and had them ask us any questions before we set up a Discord voice call with them as they used the application and gathered real time feedback. The testers are asked to rate ease of use as well as report any bugs. Most of the feedback we received pertained towards the color scheme we had used for our group chat feature, as such we swapped the colors (blue for user and grey for others) to fit the given feedback. 

### Swagger (Expert Testing)

![](https://i.imgur.com/LUsEfn8.png)

We use Swagger as a documentation generator that will parse our inline Go comments and generate extensive documentation of Data Transfer Objects (DTOs) and HTTP endpoints.

This documentation is used by us to do expert testing of the backend's code, to check if the HTTP endpoints work as intended and return the correct output and status codes.


### Adminer (Expert Testing)

Adminer is a database management tool that can be accessed in the browser to view the database's schema, data and manually perform SQL queries on.

We used Adminer in development as a form of expert testing to manually verify that our CRUD operations were working as intended and to assist in more complex SQL queries when using GORM. 

![](https://i.imgur.com/1GIUPaI.png)

From here, we can view the table schemas and view the present data. 

![](https://i.imgur.com/qdF0mM6.png)

Sample of our places data. 



## Product scope

Product scope provides you an insight into the value of planlah, and its benefits for target users.

### Target user profile:

- Singaporeans who
    - want to be able to quickly invite friends and family for an outing. 
    - want to get a quick recommendation of places to go, things to do and food to eat based on their current location. 
    - want to be able to easily discuss and vote on what they want to do for the outing, with the group gaining the maximum satisfaction. 
    - want to know the logistics (where to go next and how long we need) for the outing. 
    - want their friends to know what they are currently up to
    - want to leave a review on a place to improve the service for other Singaporeans 

### Value proposition

There is currently no application that is especially designed to facilitate the process of organizing an outing in Singapore. 

planlah will be the premier social media application that makes it easy for Singaporeans to plan and coordinate outings, get suggestions of places to go and food to eat, and ultimately enhance their lives. 

### User Stories

| Version | As a ...              | I want to ...                                      | So that I can ...                                    |
| ------- | --------------------- | -------------------------------------------------- | ---------------------------------------------------- |
| v1.0    | planlah User       | create a personal account              | begin using the platform                             |
| v1.0    | planlah User       | chat in a group        | plan an outing with my friends and family                             |
| v1.0    | planlah User       | edit my profile        | customize how I appear on planlah                           |
| v2.0    | planlah User       | vote on an outing step            | choose the place that i want to go                            |
| v2.0    | planlah User       | suggest an outing step             | plan an outing with my friends and family                           |
| v2.0    | planlah User       | search for other users on the platform             | connect with other users                         |
| v3.0    | planlah User       | post photos                                        | share my experiences and memories with my friends       |
| v3.0    | planlah User       | add other users as friends                         | connect more easily with each other on the platform  |
| v3.0    | planlah User       | chat with other users on the platform through DMs              | easily communicate without leaving planlah        |
| v3.0    | planlah User       | be recommended places to go           | discover new restaurants and places                           |
| v3.0    | planlah User       | leave a review on a place             | help other users make better decisions                           |
| v3.0    | planlah User       | view all posts made by a user            | see what a user has been up to                           |
| v3.0    | planlah User       | view a social feed            | keep up to date with what my friends have been doing                        |

### Non-Functional Requirements

1. The application should work on any android device
1. The application should be responsive - users should be able to use the app and interact intuitively with the UI with different devices

<div style="page-break-after: always;"></div>

## Glossary

- Outing - A planned itinerary where users can view the timeline of the day's activities
- Outing Step - An activity in the Outing that can be voted on.
- IDE - Integrated development environment, software applications for software development
