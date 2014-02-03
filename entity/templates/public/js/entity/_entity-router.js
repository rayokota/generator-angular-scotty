'use strict';

angular.module('<%= baseName %>')
  .config(['$routeProvider', function ($routeProvider) {
    $routeProvider
      .when('/<%= pluralize(name) %>', {
        templateUrl: 'views/<%= name %>/<%= pluralize(name) %>.html',
        controller: '<%= _.capitalize(name) %>Controller',
        resolve:{
          resolved<%= _.capitalize(name) %>: ['<%= _.capitalize(name) %>', function (<%= _.capitalize(name) %>) {
            return <%= _.capitalize(name) %>.query(function (objs) {
              // deal with Haskell Persistent json format
              for (var i = 0; i < objs.length; i++) {
                var obj = objs[i];
                obj.id = obj.key;
                delete obj.key;
                for (var prop in obj.value) {
                  obj[prop] = obj.value[prop];
                }
                delete obj.value;
              }
            });
          }]
        }
      })
    }]);
