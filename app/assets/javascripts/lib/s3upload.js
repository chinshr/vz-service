(function() {
  window.S3Upload = (function() {
    S3Upload.prototype.object_key       = 'default_name';
    S3Upload.prototype.s3SignURL        = '/signS3put';
    S3Upload.prototype.selector         = '#file_upload';
    S3Upload.prototype.withCredentials  = false;

    S3Upload.prototype.onFinishS3Put = function(publicUrl, file) {
      return console.log('base.onFinishS3Put()', publicUrl, file);
    };

    S3Upload.prototype.onProgress = function(xhr, file, percent, state) {
      return console.log('base.onProgress()', file, percent, state);
    };

    S3Upload.prototype.onError = function(status) {
      return console.log('base.onError()', status);
    };

    S3Upload.prototype.onAbort = function(file, status) {
      return console.log('base.onAbort()', status);
    };

    function S3Upload(options) {
      var option;

      if (options == null) {
        options = {};
      }

      // instance variables
      for (option in options) {
        this[option] = options[option];
      }

      // Select from dom id, dom element, or dropped files
      if (typeof(this.selector) === 'string') {
        // E.g. "#files"
        this.handleFileSelect($(this.selector)[0]);
      } else if(this.selector instanceof jQuery) {
        this.handleFileSelect(this.selector[0]);
      } else if(typeof(this.selector) === 'object') {
        this.handleFileSelect(this.selector);
      } else if (options.dropped && options.files) {
        this.handleFileSelect({files: options.files});
      }
    }

    S3Upload.prototype.handleFileSelect = function(file_element) {
      var files = file_element.files,
        results = [];
      for (i = 0, len = files.length; i < len; i++) {
        results.push(this.uploadFile( files[i] ));
      }
      return results;
    };

    S3Upload.prototype.createCORSRequest = function(method, url) {
      var xhr;
      xhr = new XMLHttpRequest();
      if (xhr.withCredentials != null) {
        xhr.open(method, url, true);
      } else if (typeof XDomainRequest !== "undefined") {
        xhr = new XDomainRequest();
        xhr.open(method, url);
      } else {
        xhr = null;
      }
      return xhr;
    };

    S3Upload.prototype.randomObjectName = function() {
      var possible = "abcdefghijklmnopqrstuvwxyz0123456789",
        result = "";
      for (var i = 0; i < 20; i++) {
        result += possible.charAt(Math.floor(Math.random() * possible.length));
      }
      return result;
    };

    S3Upload.prototype.executeOnSignedUrl = function(file, callback) {
      var _this = this,
        xhr = new XMLHttpRequest();
      xhr.withCredentials = this.withCredentials;
      xhr.open('GET', this.s3SignURL + '?object_content_type=' + file.type + '&object_key=' + this.randomObjectName(), true);
      xhr.overrideMimeType('text/plain; charset=x-user-defined');
      xhr.onreadystatechange = function(e) {
        var error, result;
        if (this.readyState === 4 && this.status === 200) {
          try {
            result = JSON.parse(this.responseText);
          } catch (_error) {
            error = _error;
            _this.onError('Signing server returned some ugly/empty JSON: "' + this.responseText + '"');
            return false;
          }
          return callback(decodeURIComponent(result.signed_request), result.url);
        } else if (this.readyState === 4 && this.status !== 200) {
          return _this.onError('Could not contact request signing server. Status = ' + this.status);
        }
      };
      return xhr.send();
    };

    S3Upload.prototype.uploadToS3 = function(file, url, publicUrl) {
      var _this = this,
        xhr = this.createCORSRequest('PUT', url);

      if (!xhr) {
        this.onError('CORS not supported');
      } else {
        xhr.onload = function(e) {
          if (xhr.status === 200) {
            _this.onProgress(xhr, file, 100, 'completed');
            return _this.onFinishS3Put(publicUrl, file);
          } else {
            return _this.onError('Upload error: ' + xhr.status);
          }
        };

        xhr.onerror = function() {
          return _this.onError('XHR error.');
        };

        xhr.upload.onprogress = function(e) {
          var percent, state;
          if (e.lengthComputable) {
            state = (e.loaded === e.total ? 'completing' : 'uploading');
            percent = Math.round((e.loaded / e.total) * 100);
            return _this.onProgress(xhr, file, percent, state);
          }
        };

        xhr.abort = function(e) {
          return _this.onAbort(file, 'aborting');
        };
      }
      xhr.setRequestHeader('Content-Type', file.type);
      xhr.setRequestHeader('x-amz-acl', 'public-read');
      return xhr.send(file);
    };

    S3Upload.prototype.uploadFile = function(file) {
      var _this = this;
      _this.onProgress(null, file, 0, 'starting');
      return this.executeOnSignedUrl(file, function(signedURL, publicURL) {
        return _this.uploadToS3(file, signedURL, publicURL);
      });
    };

    return S3Upload;
  })();

}).call(this);