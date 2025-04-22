# GovWifi Product Page

This is the product page for GovWifi. It is a [middleman site](http://middlemanapp.com/) originally copied from the [product-page-example](https://github.com/alphagov/product-page-example) repo.

## Getting Setup for Development

Software required to be installed to get the local version working are:

- ruby (recommended version is `3.4.2`)
- docker
- npm (installed with nodejs)

To pull the code from Github, enter the following into your terminal (Applications -> Utilities -> Terminal on Mac):

- `git clone https://github.com/alphagov/govwifi-product-page.git`
- `cd govwifi-product-page`
- `gem install bundler`
- `make build`
- `npm install`

You can now open the codebase in any text editor and make changes.

## Getting Started

To make the site viewable in your browser:

- `make serve`
- Open your browser and go to http://localhost:4567

## Testing Locally

Before starting, run `bundle install` in the project to ensure all necessary gems are installed.

To run tests locally, run the following command from the project root directory:

```bash
$ rspec ./spec/features/
```

## Deploying
This is deployed to github pages, via a workflow.  Has been noticed that on occasions it can 'stick' on the ```setup node``` step, if this happens, terminate the job and rerun.

## Contributing

The `source` folder contains all the pages that you will want to change, eg: `index.html.erb`. Whenever you save a change, the site will automatically reload so you can see your changes at `http://localhost:4567`.

Once you have made any changes, do the following to save your changes to git and push to github:

- `git add -A`
- `git commit -m "ADD A SHORT DESCRIPTION OF YOUR CHANGES"`
- `git push`

### External contributions

We welcome contribution suggestions from outside of the GovWifi team, but the process is slightly different:

**How to contribute**

1. Fork the project
2. Create a feature or fix branch
3. Make your changes (with tests if applicable)
4. Raise a pull request

The pull request must be reviewed by members of the GovWifi team and the content community.

## License

The documentation is [© Crown copyright][copyright] and available under the terms
of the [Open Government 3.0][ogl] licence.

[mit]: LICENCE
[copyright]: http://www.nationalarchives.gov.uk/information-management/re-using-public-sector-information/uk-government-licensing-framework/crown-copyright/
[ogl]: http://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/
