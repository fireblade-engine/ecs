# Fireblade ECS (Entity-Component-System)
<!--One Paragraph of project description goes here

A short description of the motivation behind the creation and maintenance of the project. This should explain **why** the project exists.-->

This is a lightweight, easy to use, fast and simple [Entity-Component-System](https://en.wikipedia.org/wiki/Entity–component–system) implementation for Swift. It is developed and maintained as part of the Fireblade Game Engine project.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

* [Swift Package Manager (SPM)](https://github.com/apple/swift-package-manager)
* [Swiftlint](https://github.com/realm/SwiftLint) for linting - (optional)
* [Jazzy](https://github.com/realm/jazzy) for documentation - (optional)

### Installing

Fireblade ECS is available for all platforms that support [Swift 4.0+](https://swift.org/) and the [Swift Package Manager (SPM)](https://github.com/apple/swift-package-manager).

Extend the following lines in your `Package.swift` file or use it to create a new project.

```
// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "YourPackageName",
    dependencies: [
        .package(url: "https://github.com/ctreffs/fireblade-ecs.git", from: "0.3.0")
    ],
    targets: [
        .target(
            name: "YourTargetName",
            dependencies: ["FirebladeECS"])
    ]
)

```

### Contribution 

Clone this repository into your favorite folder.
If you like to edit the project via Xcode use the following to generate the Xcode Project.

```
cd <PATH_TO_REPOSITORY>
swift package generate-xcodeproj
open FirebladeECS.xcodeproj
```


End with an example of getting some data out of the system or using it for a little demo


## Code Example

Show what the library does as concisely as possible, developers should be able to figure out **how** your project solves their problem by looking at the code example. Make sure the API you are showing off is obvious, and that your code is short and concise.


## Running the tests

Explain how to run the automated tests for this system

### Break down into end to end tests

Explain what these tests test and why

```
Give an example
```

### And coding style tests

Explain what these tests test and why

```
Give an example
```

## Deployment

Add additional notes about how to deploy this on a live system

## Built With

* [Dropwizard](http://www.dropwizard.io/1.0.2/docs/) - The web framework used
* [Maven](https://maven.apache.org/) - Dependency Management
* [ROME](https://rometools.github.io/rome/) - Used to generate RSS Feeds

## Contributing

Please read [CONTRIBUTING.md](https://gist.github.com/PurpleBooth/b24679402957c63ec426) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/your/project/tags). 

## Authors

* **Billie Thompson** - *Initial work* - [PurpleBooth](https://github.com/PurpleBooth)

See also the list of [contributors](https://github.com/your/project/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* Hat tip to anyone who's code was used
* Inspiration
* etc
