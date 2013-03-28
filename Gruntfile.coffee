module.exports = (grunt) ->

  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'

    clean:
      client: 'web'
      server: 'server'

    coffee:
      client:
        files: [{src: 'src/launch.coffee', dest: 'web/launch.js'}]
      server:
        files: [{src: 'src/main.coffee', dest: 'server/main.js'}]

    copy:
      client:
        files: [
          {src: ['vendor/**'], dest: 'web/'},
          {expand: true, cwd: 'src/', src: ['**/*.{css,html}'], dest: 'web/'}
        ]

  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-copy'

  grunt.registerTask 'default', 'Clean & build everything', ['clean', 'coffee', 'copy']

