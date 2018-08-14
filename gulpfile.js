// jshint -W117

'use strict';

//----
// Dependencies
//----

// jshint ignore:start
var gulp          = require('gulp');
var sass          = require('gulp-sass');
var cssnano       = require('gulp-cssnano');
var sourcemaps    = require('gulp-sourcemaps');
var autoprefixer  = require('gulp-autoprefixer');
var concat        = require('gulp-concat');
var uglify        = require('gulp-uglify');
var rename        = require('gulp-rename');
var moment        = require('moment');
var notify        = require('gulp-notify');
var svgo          = require('gulp-svgo');
var svgSymbols    = require('gulp-svg-symbols');
var browserSync   = require('browser-sync').create();
var newer         = require('gulp-newer');
var imagemin      = require('gulp-imagemin');
var rename        = require('gulp-rename');
// jshint ignore:end

//----
// Paths
//----

var config = {
  // .Source
  src     : './Sources/App/assets/',
  srcScss : './Sources/App/assets/scss',
  srcJS   : './Sources/App/assets/js',
  srcImg  : './Sources/App/assets/img',
  // .Public
  pub     : './public/assets',
  pubCss  : './public/assets/css',
  pubJS   : './public/assets/js',
  pubImg  : './public/assets/img'
};

//----
// Tasks
//----

// Compile SCSS (https://github.com/dlmanning/gulp-sass)
// Sitewide
gulp.task('scss:common', function () {
  return gulp.src(config.srcScss + '/common/common.scss')
    .pipe(sourcemaps.init())
    .pipe(sass().on('error', sass.logError))
    .pipe(sourcemaps.write())
    // .pipe(autoprefixer({
    //   browsers: ['last 1 version']
    // }))

    // .pipe(cssnano())
    .pipe(gulp.dest(config.pubCss));
});

// Font
gulp.task('scss:font', function () {
  return gulp.src(config.srcScss + '/font/inter-ui.scss')
    .pipe(sass().on('error', sass.logError))
    .pipe(gulp.dest(config.pubCss));
});

// Javascript
gulp.task('js:app', function () {
  return gulp.src([
      config.srcJS + '/vendor/**/*.js',
      config.srcJS + '/plugins/**/*.js',
      config.srcJS + '/components/**/*.js',
      config.srcJS + '/pages/**/*.js',
      config.srcJS + '/_main.js'
    ])
    .pipe(concat('app.js'))
    .pipe(uglify())
    .pipe(rename({
      extname: ".min.js"
    }))
    .pipe(gulp.dest(config.pubJS))
    .pipe(notify('Uglified JavaScript (' + moment().format('MMM Do h:mm:ss A') + ')'));
});

// Optimize Images (https://github.com/sindresorhus/gulp-imagemin)
gulp.task('images', function() {
  return gulp.src(config.srcImg)
    // Only apply to new or modified images.
    .pipe(newer(config.srcImg))
    // Optimize
    .pipe(imagemin())
    .pipe(gulp.dest(config.pubImg));
});

// Optimize SVG (https://github.com/corneliusio/gulp-svgo)
// - *** Unnecessary when utilizing svgSymbols
gulp.task('svg', function () {
  return gulp.src(config.srcImg + '/**/*.svg')
    .pipe(svgo({ 
      plugins: [
        {
          removeViewBox: false
        }
      ]
    }))
    .pipe(rename({ extname: '.leaf' }))
    .pipe(gulp.dest('./Resources/Views/svg'));
});

// Create SVG Symbols - https://github.com/Hiswe/gulp-svg-symbols
gulp.task('svgSymbols', function () {
  return gulp.src(config.srcImg + '/**/*.svg')
    .pipe(svgSymbols({
      templates: ['default-svg'] // only save svg file (no css)
    }))
    .pipe(rename('svg.leaf')) // rename to .leaf so we can embed in template
    .pipe(gulp.dest('./Resources/Views/components')); // .leaf templates must be within /Views
});

// Synchronized Browser Testing
// - Automatically update browser on file changes.
gulp.task('browserSync', function() {
  browserSync.init({
    // local vhost url
    proxy: 'sharecuts.test:8080',
    // inject if any of these files are changed
    files: [
      config.pub + '/**/*.*', './views/**/*.*'
    ],
    // Don't open URL automatically
    open: false
  });
});

// Watch
// - Watch files/directories for changes, run tasks and update browser.
gulp.task('watch', ['browserSync', 'scss:common'], function () {
  gulp.watch(config.srcScss + '/common/**/*.scss', ['scss:common']).on('change', browserSync.reload);
  gulp.watch(config.srcScss + '/font/*.scss', ['scss:font']).on('change', browserSync.reload);
  gulp.watch(config.srcJS + '/**/*.js', ['js:app']).on('change', browserSync.reload);
  gulp.watch(config.srcImg + '/*.{jpg,png,gif}', ['images']).on('change', browserSync.reload);
  gulp.watch(config.srcImg + '/*.svg', ['svg', 'svgSymbols']).on('change', browserSync.reload);

  gulp.watch('**/*.php').on('change', browserSync.reload);
});
