'use strict'

LIVERELOAD_PORT = 35730
lrSnippet = require('connect-livereload')(port: LIVERELOAD_PORT)
exec = require('child_process').execSync;

# var conf = require('./conf.'+process.env.NODE_ENV);
mountFolder = (connect, dir) ->
  connect.static require('path').resolve(dir)

app_name = require('./bower.json').name

# # Globbing
# for performance reasons we're only matching one level down:
# 'test/spec/{,*}*.js'
# use this if you want to recursively match all subfolders:
# 'test/spec/**/*.js'
module.exports = (grunt) ->
  
    
  require('load-grunt-tasks') grunt
  require('time-grunt') grunt
  # configurable paths
  
  yeomanConfig =
    bower:       'bower_components'
    src:         'src'
    dist:        'dist'
    tmp:         'tmp'
  do ->
    (maybe_dist = grunt.option('dist')) and 
    (typeof maybe_dist is 'string') and 
    yeomanConfig.dist = maybe_dist
  do ->
    (maybe_tmp = grunt.option('tmp')) and 
    (typeof maybe_tmp is 'string') and 
    yeomanConfig.tmp = maybe_tmp
    
  grunt.loadNpmTasks 'grunt-angular-templates'
  grunt.loadNpmTasks 'grunt-bake'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-sass'
  grunt.loadNpmTasks 'grunt-html-angular-validate'
  grunt.loadNpmTasks 'grunt-preprocess'
  grunt.loadNpmTasks 'grunt-string-replace'
  
  grunt.initConfig
    yeoman: yeomanConfig
    
    #################################################
    #                  livereload                   #
    #################################################
    # watch: cada vez que un archivo cambia 
    # dentro de 'files' se ejecutan las correspodientes 'tasks'
    watch:

      coffee_dist:
        files: ['<%= yeoman.src %>/**/*.coffee']
        tasks: ['coffee:dist']
      sass_dist:
        files: ['<%= yeoman.src %>/**/*.scss']
        tasks: ['sass:dist']
      templates:
        files: ['<%= yeoman.src %>/templates/**/*.html']
        tasks: ['copy:templates']
      assets:
        files: ['<%= yeoman.src %>/assets/**/*']
        tasks: ['copy:assets']
      compile:
        files: ['<%= yeoman.src %>/**/*.html','<%= yeoman.src %>/editor/templates.json']
        tasks: ['compile:default']
        
      # watch.livereload: files which demand the page reload
      livereload:
        options:
          livereload: LIVERELOAD_PORT
        files: [
          '<%= yeoman.dist %>/**/*'
          'demo/**/*'
        ]
    
    connect:
      options:
        port: 9002
        # default 'localhost'
        # Change this to '0.0.0.0' to access the server from outside.
        hostname: "localhost"
      livereload:
        options:
          middleware: (connect) ->
            [lrSnippet, mountFolder(connect, '.')]

    open:
      server:
        url: 'http://<%= connect.options.hostname %>:<%= connect.options.port %>/dist/'
        
    clean:
      dist:
        files: [
          dot: true
          src: ['<%= yeoman.dist %>/**/*','!<%= yeoman.dist %>/bower_components/**']
        ]
      tmp:
        files: [
          dot: true
          src: ['<%= yeoman.tmp %>/**/*']
        ]
        
    #################################################
    #                    styles                     #
    #################################################      
      
    sass:
      dist:
        options:
          style: 'expanded'
        files: [
          expand: true
          cwd: '<%= yeoman.src %>'
          src: '**/*.scss'
          dest: '<%= yeoman.dist %>'
          ext: '.css'
        ]

    #################################################
    #                  copy helper                  #
    #################################################  

    copy:
      index:
        files: [
          expand: true
          cwd: '<%= yeoman.src %>'
          src: 'index.html'
          dest: '<%= yeoman.dist %>'
        ]
      templates:
        files: [
          expand: true
          cwd: '<%= yeoman.src %>/templates'
          src: '**/*.html'
          dest: '<%= yeoman.dist %>/templates'
        ]
      assets:
        files: [
          expand: true
          cwd: '<%= yeoman.src %>/assets'
          src: '**/*'
          dest: '<%= yeoman.dist %>/assets'
        ]
        
    #################################################
    #                    scripts                    #
    #################################################  

    coffee:
      dist:
        options:
          bare: true
          sourceMap: false
          sourceRoot: ''
        files: [
          expand: true
          cwd: '<%= yeoman.src %>'
          src: ['**/*.coffee']
          dest: '<%= yeoman.dist %>'
          ext: '.js'
        ]

  grunt.registerTask 'compile', (target) ->
    replacer = (exp) -> new RegExp "(<\\!\\s*\\-\\-(#{exp})\\-\\-\\s*>)|(<\\%\\s?(#{exp})\\s?\\%>)", 'g'
    
    #read metadata
    config_path = yeomanConfig.src + '/editor/templates.json' 
    config = grunt.file.readJSON config_path
    first = config.templates[0]
    
    #get index.html template and replace patter
    index = grunt.file.read yeomanConfig.src + '/' + 'index.html'
    grunt.file.write (yeomanConfig.dist + '/' + 'index.html'), index.replace(replacer('first'), first.file)
    
    #create editor directory
    editor_dir = yeomanConfig.dist + '/' + 'editor'
    create_editor_dir = 'mkdir -p ' + editor_dir
    exec create_editor_dir, cdw: __dirname
    
    #build editor instaces
    editor = grunt.file.read yeomanConfig.src + '/editor/main.html'
    
    previous_content = ''
    src_dir = yeomanConfig.src + '/templates'
    for tmpl, index in config.templates
      content = grunt.file.read src_dir + '/' + tmpl.file + '.html'
      next_tmpl = config.templates[index + 1] or ''
      
      example = editor.replace(replacer('element\\-file'), tmpl.file)
      example = example.replace(replacer('element\\-description'), tmpl.description)
      example = example.replace(replacer('next\\-element\\-file'), next_tmpl.file)
      example = example.replace(replacer('element\\-content'), content)
      if not tmpl.skipPrevious
        example = example.replace(replacer('provious\\-element\\-content'), previous_content)
      
      grunt.file.write (editor_dir + '/' + tmpl.file + '.html'), example
      
      previous_content = content
    
  grunt.registerTask 'server', (target) ->
    grunt.task.run [
      'clean:dist'
      'clean:tmp'
      'compile:default'
      'copy:templates'
      'copy:assets'
      'coffee:dist'
      'sass:dist'
      'connect:livereload'
      'open'
      'watch'
    ]
