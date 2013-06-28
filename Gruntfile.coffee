module.exports = (grunt) ->

  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'

    clean:
      client: 'web'
      server: 'server'
      test: ['test/**/*-test.js']

    coffee:
      client:
        files: [{src: 'src/launch.coffee', dest: 'web/launch.js'}]
      server:
        files:
          'server/main.js': 'src/main.coffee'
          'server/mark_down_message.js': 'src/mark_down_message.coffee'
          'server/static-web-request-handler.js': 'src/static-web-request-handler.coffee'
      test:
        files:
          'test/truth-test.js': 'test/truth-test.coffee'

    copy:
      client:
        files: [
          {src: ['vendor/**'], dest: 'web/'},
          {expand: true, cwd: 'src/', src: ['**/*.{css,html,wav}'], dest: 'web/'}
        ]

    simplemocha:
      options:
        timeout: 3000
        ignoreLeaks: false
        ui: 'bdd'
        report: 'tap'
      all:
        src: ['test/**/*-test.js']

    uglify:
      client:
        files: [{src: 'web/launch.js', dest: 'web/launch.min.js'}]

  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-simple-mocha'

  grunt.registerTask 'default', 'Clean & build everything', ['clean', 'coffee', 'copy', 'simplemocha', 'uglify']

