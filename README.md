Dock Landing
============

About
-----

This project defines the landing page for the Dock project.

Development
-----------

### Build environment

The build environment for the project is defined in `build.Dockerfile`. The
build environment can be replicated locally by following the setup defined in
the Dockerfile, or Dock can be used to mount the local directory in the build
environment by running `dock shell`.

### Running

The project can be run locally using `npm run dev`, or can be run using Dock by
running `npx vite --host` under `dock shell`.

### Building

The project can be run locally using `npm run build`. This can also be run under
`dock shell`, or by running the following:

    dock run-in build-env: npm run build

Running the build in any of the above ways will generate the built artefacts to
the local `dist` directory.

### Testing

The project can be tested locally using `npm test`.This can also be run under
`dock shell`, or by running the following:

    dock run-in build-env: npm test

A subset of integration tests can be run by passing name patterns to `npm test`:

    npm test dir

The commands above will run all integration tests whose name contains "dir".
