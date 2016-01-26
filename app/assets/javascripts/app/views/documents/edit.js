App.Views.DocumentsEdit = App.Views.DocumentsBase.extend({
  template: JST['documents/edit'],
  users: {},

  initialize: function() {
    App.Views.DocumentsBase.prototype.initialize.call(this); // super
    _.bindAll(this, "presenceCallback", "messageCallback",
      "hereNowCallback", "fetchUser", "fetchUserUnlessPresent",
      "isUserPresent", "isUserSelf", "publish");
  },

  initPubnub: function() {
    var _this = this;

    this.pubnub = PUBNUB.init({
      publish_key: VZ.config.pubnub.publish_key,
      subscribe_key: VZ.config.pubnub.subscribe_key,
      uuid: App.currentUser.attributes.username,
      heartbeat: 120,
      heartbeat_interval: 30,
      ssl: VZ.isSSL()
    });

    this.pubnub.subscribe({
      channel: this.channel(),
      presence: this.presenceCallback,
      message: this.messageCallback,
      state: App.currentUser.attributes
    });

    this.pubnub.here_now({
      channel : this.channel(),
      callback : this.hereNowCallback
    });

    // Publish content editor's content
    this.contentEditor.on('text-change', function(delta, source) {
      if (source === 'user') {
        if (_.keys(_this.users).length > 0) {
          var envelope = {'content-editor': {uuid: App.currentUser.attributes.username, 'text-change': {delta: delta}}};
          _this.publish(envelope);
        }
      }
    });

    /* Publish content editor's cursor selections */
    this.contentEditor.on('selection-change', function(range) {
      if (range) {
        if (_.keys(_this.users).length > 0) {
          var envelope = {'content-editor': {uuid: App.currentUser.attributes.username, 'selection-change': {range: range}}};
          _this.publish(envelope);
        }
      }
    });
  },

  publish: function(envelope) {
    var _this = this;
    this.pubnub.publish({
      channel: this.channel(),
      message: envelope,
      callback: function(status) {
        console.log("-> publish('content-editor->text-change') ", status);
      },
      error: function(status) {
        console.log(JSON.stringify(status));
        _this.publish(envelope);
      }
    });
  },

  initUnload: function() {
    var _this = this;
    var confirm = function(event) {
      _this.pubnub.unsubscribe({
        channel : _this.channel(),
      });
    };
    window.onbeforeunload = confirm;
  },

  presenceCallback: function(message) {
    var _this = this;
    if (message.action === "join" && !_this.isUserSelf(message.uuid)) {
      this.fetchUserUnlessPresent(message.uuid);
    } else if(message.action === "leave" && message.uuid !== App.currentUser.attributes.username) {
      _this.users[message.uuid].destroy();
    } else if(message.action === "timeout" && message.uuid !== App.currentUser.attributes.username) {
      _this.users[message.uuid].destroy();
    }
    console.log("-> presence: ", message);
  },

  messageCallback: function(message) {
    if (message['content-editor'] && message['content-editor'].uuid !== App.currentUser.attributes.username) {
      var envelope = message['content-editor'],
        uuid = envelope.uuid;

      this.fetchUserUnlessPresent(uuid);
      if (envelope['text-change']) {
        this.contentEditor.updateContents(envelope['text-change'].delta);
      } else if(envelope['selection-change']) {
        var user = this.users[envelope.uuid],
          range = envelope['selection-change'].range;
        if (user && range) {
          user.moveCursor(user.model.attributes.username, range.end);
        }
      }
    }
    console.log("-> message: ", message);
  },

  hereNowCallback: function(message) {
    if (message.uuids.length > 0) {
      for (var i = 0; i < message.uuids.length; i++) {
        var uuid = message.uuids[i];
        if (!this.isUserSelf(uuid)) {
          this.fetchUserUnlessPresent(uuid);
        }
      }
    }
  },

  render: function() {
    this.$el.html(this.template(this.model.attributes));
    if (this.model.ok) {
      this.initSharePopover().render();
      this.initPublishPopover().render();
      this.initEditor();
      this.initContentEditorFormatPopover().render();
      this.initPlayer();
      this.initUserInitials().render({style: "z-index:1;"});
      this.initTagEditor();
      this.initPubnub();
      this.initUnload();
      this.show();
    } else if (this.model.errors) {
      this.showPageError();
    }

    return this;
  },

  show: function() {
    $('#document-loading').hide();
    $('#document-edit').show();
  },

  showPageError: function() {
    $('#loading').hide();
    $('#document-load-error').show();
  },

  isEdit: function() { return true; },

  channel: function() {
    return "vz-document-edit-" + this.model.attributes.slug_id;
  },

  isUserPresent: function(uuid) {
    return typeof(this.users[uuid]) === 'undefined' ? false : true;
  },

  isUserSelf: function(uuid) {
    return typeof(uuid) !== "undefined" && uuid === App.currentUser.attributes.username;
  },

  fetchUserUnlessPresent: function(uuid) {
    if (typeof(uuid) !== 'undefined' && !this.isUserPresent(uuid)) {
      this.fetchUser(uuid);
    }
  },

  fetchUser: function(uuid) {
    var _this = this;
    if (typeof(uuid) !== 'undefined') {
      this.pubnub.state({
        channel: this.channel(),
        uuid: uuid,
        callback: function(attributes) {
          if (!_this.isUserPresent(attributes.username)) {
            var model = new App.Models.User(attributes);
            var user = new App.Views.DocumentsUserInitial({
              model: model,
              parent: _this
            });
            user.render({style: "z-index:0;"}).moveX(18 + Math.floor(Math.random() * 13));
            _this.users[attributes.username] = user;

            /* add author */
            // _this.contentEditorAuthorship.addAuthor(attributes.username, attributes.css_hex_color);
            _this.contentEditorAuthorship.addAuthor(attributes.username);

            /* initialize cursor */
            _this.contentEditorCursorManager.setCursor(attributes.username,
              0, // _this.contentEditor.getLength() - 1,
              attributes.name, attributes.css_hex_color);
          }
        }
      });
    }
  }
});