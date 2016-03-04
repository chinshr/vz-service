VZ._social = (function() {
  var url = VZ.baseURL + document.location.pathname,
    trackingCodes = VZ.trackingCodes;

  /* facebook init */
  (function(d, debug){
     var js, id = 'facebook-jssdk', ref = d.getElementsByTagName('script')[0];
     if (d.getElementById(id)) {return;}
     js = d.createElement('script'); js.id = id; js.async = true;
     js.src = "//connect.facebook.net/en_US/all" + (debug ? "/debug" : "") + ".js";
     ref.parentNode.insertBefore(js, ref);
  }(document, /* debug */ false));

  /* twitter init */
  window.twttr = (function (d,s,id) {
    var t={}, js, fjs = d.getElementsByTagName(s)[0];
    if (d.getElementById(id)) return; js=d.createElement(s); js.id=id;
    js.src="//platform.twitter.com/widgets.js"; fjs.parentNode.insertBefore(js, fjs);
    return window.twttr || (t = { _e: [], ready: function(f){ t._e.push(f); } });
  }(document, "script", "twitter-wjs"));

  /* linkedin init */
  (function(d, s) {
    var t = d.createElement(s);
    t.type  = "text/javascript";
    t.src   = "//platform.linkedin.com/in.js";
    t.lang  = "en_US";
    t.async = true;
    d.getElementsByTagName("head")[0].appendChild(t);
  }(document, 'script'));

  var setupTwitter = function setupTwitter(tweetURL, openAfterSetup) {
    var hashtag = VZ.config.twitter.hashtag,
      hashtags = VZ.config.twitter.hashtags,
      tweetPrefix = VZ.config.twitter.prefix;

    if (!('isTweetURLSet' in this)) { this.isTweetURLSet = false; }
    if (!tweetURL && this.isTweetURLSet) {return;}
    var url = VZ.baseURL + (tweetURL ? tweetURL : document.location.pathname);
    var title = $('head meta[property="og:title"]').attr("content") || "";
    var image = $('head meta[property="og:image"]').attr("content");

    if (trackingCodes && ('twitter' in trackingCodes)) url += "?r=" + trackingCodes.twitter;
    var href = 'https://twitter.com/intent/tweet?related=' + hashtag + '&url=' + encodeURIComponent(url) + '&text=' + encodeURIComponent(tweetPrefix + title) + '&hashtags=' + encodeURIComponent(hashtags);
    $('.social-networks .twitter a').attr("data-href", href);
    this.isTweetURLSet = true;
  }

  var setupLinkedIn = function setupLinkedIn(shareURL, openAfterSetup) {
    if (!('isLinkedInURLSet' in this)) {this.isLinkedInURLSet = false;}
    if (!shareURL && this.isLinkedInURLSet) {return;}
    var url  = VZ.baseURL + (shareURL ? shareURL : document.location.pathname),
      title  = $('head meta[property="og:title"]').attr("content") || "";
      image  = $('head meta[property="og:image"]').attr("content");
      prefix = VZ.config.linkedin.prefix;

    if (trackingCodes && ('linkedin' in trackingCodes)) {url += "?r=" + trackingCodes.linkedin;}
    var href = 'https://www.linkedin.com/cws/share?url=' + encodeURIComponent(url) + '&text=' + encodeURIComponent(prefix + title);
    $('.social-networks .linkedin a').attr("data-href", href);
    this.isLinkedInURLSet = true;
  }

  var bind = function bind() {
    // http://stackoverflow.com/questions/25619418/how-do-i-implement-basic-share-social-buttons-with-font-awesome-fonts

    // facebook
    $(".social-networks .facebook a, .social-networks .facebook button").each(function(index, element) {
      var href;
      if ($(this).data("href")) {
        href = $(this).data("href");
      } else {
        href = url;
      }
      $(this)
        .attr("href", 'http://www.facebook.com/sharer/sharer.php?u=' + encodeURIComponent(href))
        .on('click', function(e) {
          var href = $(this).attr("href"),
            fburl = decodeURIComponent( href.substring(href.indexOf("u=") > -1 ? href.indexOf("u=") + 2 : 0) );

          if (trackingCodes && ('facebook' in trackingCodes)) {
            href += "%3Fr%3D" + trackingCodes.facebook;
          }

          window.open(href, 'sharer', "toolbar=no,menubar=no,scrollbars=no,location=no,directories=no,width=626,height=300");
          VZ.trackEvent("facebook-button-clicked", {url : fburl});
          return false;
        });
    });

    // twitter
    setupTwitter();
    $('.social-networks .twitter a, .social-networks .twitter button').on('click', function(e) {
      e.preventDefault();
      var href   = this.getAttribute('data-href');
      var title;
      if ($(this).attr('data-title')) {
        title = encodeURIComponent('"' + $(this).attr('data-title') + '"');
      } else {
        title = encodeURIComponent(VZ.config.twitter.prefix);
      }
      var tw_url = decodeURIComponent(href.substring(href.lastIndexOf("url=") > -1 ? href.lastIndexOf("url=") + 4 : 0));
      if (trackingCodes && ('twitter' in trackingCodes)) {
        tw_url += "?r=" + trackingCodes.twitter;
      }
      href = 'https://twitter.com/intent/tweet?related=' + 'voyzes' + '&url=' + encodeURIComponent(tw_url) + '&text=' + title + '&via=' + encodeURIComponent(VZ.config.twitter.hashtags);
      window.open(href, '', 'height=250,width=450');
      VZ.trackEvent("twitter-button-clicked", {url : tw_url});
    });

    // linkedin
    setupLinkedIn();
    $('.social-networks .linkedin a, .social-networks .linkedin button').on('click', function(e) {
      e.preventDefault();
      var href   = this.getAttribute('data-href');
      var title;
      if ($(this).attr('data-title')) {
        title = encodeURIComponent($(this).attr('data-title'));
      } else {
        title = encodeURIComponent(VZ.config.linkedin.prefix);
      }
      var li_url = decodeURIComponent(href.substring(href.lastIndexOf("url=") > -1 ? href.lastIndexOf("url=") + 4 : 0));
      if (trackingCodes && ('linkedin' in trackingCodes)) {
        li_url += "?r=" + trackingCodes.linkedin;
      }
      href = 'https://www.linkedin.com/cws/share?url=' + encodeURIComponent(li_url) + '&summary=' + encodeURIComponent(title) + '&title=' + encodeURIComponent(title);
      window.open(href, '', 'height=400,width=450');
      VZ.trackEvent("linkedin-button-clicked", {url : li_url});
    });

  };

  var unbind = function bind() {
    $('.social-networks .facebook a, .social-networks .facebook button').off('click');
    $('.social-networks .twitter a, .social-networks .twitter button').off('click');
    $('.social-networks .linkedin a, .social-networks .linkedin button').off('click');
  };

  $(function() {
    bind();
  });

  VZ.social = {facebook: {}, twitter: {}, linkedin: {}};
  VZ.social.bind = bind;
  VZ.social.unbind = unbind;
})();
