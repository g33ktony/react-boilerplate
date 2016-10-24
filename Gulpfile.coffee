gulp       = require 'gulp'
concat     = require 'gulp-concat'
connect    = require 'gulp-connect'
less       = require 'gulp-less'
minifyCSS  = require 'gulp-clean-css'
minifyHTML = require 'gulp-htmlmin'
minIMG     = require 'gulp-imagemin'
uglify     = require 'gulp-uglify'
watch      = require 'gulp-watch'
bowerMain  = require 'main-bower-files'
gulpFilter = require 'gulp-filter'
rename     = require 'gulp-rename'
flatten    = require 'gulp-flatten'
inject     = require 'gulp-inject'
babel      = require 'gulp-babel'

config     = require './config/gulp.json'
server     = require './config/server.json'

gulp.task 'libraries', ->

  jsFilter    = gulpFilter [ '*.js', '**/*.js' ], { restore : true }
  cssFilter   = gulpFilter [ '*.css', '**/*.css' ], { restore : true }
  lessFilter  = gulpFilter [ '*.less', '**/*.less' ], { restore : true }
  fontFilter  = gulpFilter ['**/*.eot', '**/*.woff', '**/*.woff2', '**/*.svg', '**/*.ttf'], { restore : true }
  imageFilter = gulpFilter ['**/*.gif', '**/*.png', '**/*.svg', '**/*.jpg', '**/*.jpeg'], { restore : true }

  gulp
    .src bowerMain()
    # JS
    .pipe jsFilter
    .pipe uglify()
    .pipe rename( { suffix: ".min" } )
    .pipe gulp.dest('dist/lib/js')
    .pipe jsFilter.restore
    # CSS
    .pipe cssFilter
    .pipe minifyCSS( { compatibility: 'ie8' } )
    .pipe rename( { suffix: ".min" } )
    .pipe gulp.dest('dist/lib/css')
    .pipe cssFilter.restore
    # LESS
    .pipe lessFilter
    .pipe less().on('error', (err) ->
      console.log err.message
      @emit 'end'
    )
    .pipe minifyCSS( { compatibility: 'ie8' } )
    .pipe rename( { suffix: ".min" } )
    .pipe gulp.dest('dist/lib/css')
    .pipe lessFilter.restore
    # Fonts
    .pipe fontFilter
    .pipe flatten()
    .pipe gulp.dest('dist/lib/fonts')
    .pipe fontFilter.restore
    # Images
    .pipe imageFilter
    .pipe flatten()
    .pipe gulp.dest('dist/lib/images')
    .pipe imageFilter.restore
  return

# Compile LESS
gulp.task 'less', ->
  conf = config.less
  gulp
    .src conf.source
    .pipe less().on( 'error', ( err ) ->
      console.log err.message
      @emit 'end'
    )
    .pipe minifyCSS( { compatibility: 'ie8' } )
    .pipe concat( conf.file )
    .pipe gulp.dest( conf.dest )
  return

# App
gulp.task 'app', ->
  conf = config.app
  gulp
    .src conf.source
    .pipe babel()
    .pipe uglify()
    .pipe gulp.dest( conf.dest )
  return

# Index
gulp.task 'index', [ 'libraries' ], ->
  conf = config.index
  target = gulp.src( conf.source )
  sources = gulp.src [ 'dist/lib/js/react.min.js', 'dist/lib/js/*.js', 'dist/lib/css/*.css' ], { read: false }
  target
    .pipe inject( sources, { ignorePath: 'dist', addRootSlash: false } )
    # .pipe minifyHTML( { collapseWhitespace: true } )
    .pipe gulp.dest( conf.dest )
  return

# Minify images
gulp.task 'images', ->
  conf = config.images
  gulp
    .src conf.source
    .pipe minIMG()
    .pipe gulp.dest( conf.dest )
  return

gulp.task 'compile', [
  'libraries'
  'app'
  'less'
  'index'
  'images'
]

# Server
gulp.task 'server', ->
  connect.server
    root       : server.root
    port       : server.port
    livereload : true
  return

# Reload
gulp.task 'reload', ->
  gulp
    .src config.dist
    .pipe connect.reload()
  return

gulp.task 'watch', ->
  gulp.watch [ config.app.source ], [ 'app' ]
  gulp.watch [ config.less.source ], [ 'less' ]
  gulp.watch [ config.templates.source ], [ 'templates' ]
  gulp.watch [ config.index.source ], [ 'index' ]
  gulp.watch [ config.images.source ], [ 'images' ]
  gulp.watch [ config.dist ], [ 'reload' ] # livereload

gulp.task 'default', [
  'compile'
  'server'
  'watch'
]
