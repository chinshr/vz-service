// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require jquery-ui/core
//= require jquery-ui/widget
//= require lib/chosen.jquery
//= require lib/select2
//= require lib/bootstrap
//= require lib/rails.validations
//= require lib/rails.validations.bootstrap
//= require lib/detect_timezone
//= require underscore
//= require backbone
//= require lib/backbone/backbone.validation
//= require lib/backbone/backbone.validation.config
//= require lib/simply-toast
//= require lib/s3upload
//= require web/documents
//= require app
//= require_tree ../templates
//= require_tree ./models
//= require_tree ./collections
//= require_tree ./views
//= require_tree ./routers
//= require_tree ./web

var VZ = (function() {
  var config = {
    domain: "voyz.es",
    twitter: {hashtag: "voyzes", hashtags: "voyzes"}
  };

  var isProduction = document.location.href.indexOf("www." + config.domain) > 0;

  function MD5(s) {function L(k,d){return(k<<d)|(k>>>(32-d))}function K(G,k){var I,d,F,H,x;F=(G&2147483648);H=(k&2147483648);I=(G&1073741824);d=(k&1073741824);x=(G&1073741823)+(k&1073741823);if(I&d){return(x^2147483648^F^H)}if(I|d){if(x&1073741824){return(x^3221225472^F^H)}else{return(x^1073741824^F^H)}}else{return(x^F^H)}}function r(d,F,k){return(d&F)|((~d)&k)}function q(d,F,k){return(d&k)|(F&(~k))}function p(d,F,k){return(d^F^k)}function n(d,F,k){return(F^(d|(~k)))}function u(G,F,aa,Z,k,H,I){G=K(G,K(K(r(F,aa,Z),k),I));return K(L(G,H),F)}function f(G,F,aa,Z,k,H,I){G=K(G,K(K(q(F,aa,Z),k),I));return K(L(G,H),F)}function D(G,F,aa,Z,k,H,I){G=K(G,K(K(p(F,aa,Z),k),I));return K(L(G,H),F)}function t(G,F,aa,Z,k,H,I){G=K(G,K(K(n(F,aa,Z),k),I));return K(L(G,H),F)}function e(G){var Z;var F=G.length;var x=F+8;var k=(x-(x%64))/64;var I=(k+1)*16;var aa=Array(I-1);var d=0;var H=0;while(H<F){Z=(H-(H%4))/4;d=(H%4)*8;aa[Z]=(aa[Z]|(G.charCodeAt(H)<<d));H++}Z=(H-(H%4))/4;d=(H%4)*8;aa[Z]=aa[Z]|(128<<d);aa[I-2]=F<<3;aa[I-1]=F>>>29;return aa}function B(x){var k="",F="",G,d;for(d=0;d<=3;d++){G=(x>>>(d*8))&255;F="0"+G.toString(16);k=k+F.substr(F.length-2,2)}return k}function J(k){k=k.replace(/rn/g,"n");var d="";for(var F=0;F<k.length;F++){var x=k.charCodeAt(F);if(x<128){d+=String.fromCharCode(x)}else{if((x>127)&&(x<2048)){d+=String.fromCharCode((x>>6)|192);d+=String.fromCharCode((x&63)|128)}else{d+=String.fromCharCode((x>>12)|224);d+=String.fromCharCode(((x>>6)&63)|128);d+=String.fromCharCode((x&63)|128)}}}return d}var C=Array();var P,h,E,v,g,Y,X,W,V;var S=7,Q=12,N=17,M=22;var A=5,z=9,y=14,w=20;var o=4,m=11,l=16,j=23;var U=6,T=10,R=15,O=21;s=J(s);C=e(s);Y=1732584193;X=4023233417;W=2562383102;V=271733878;for(P=0;P<C.length;P+=16){h=Y;E=X;v=W;g=V;Y=u(Y,X,W,V,C[P+0],S,3614090360);V=u(V,Y,X,W,C[P+1],Q,3905402710);W=u(W,V,Y,X,C[P+2],N,606105819);X=u(X,W,V,Y,C[P+3],M,3250441966);Y=u(Y,X,W,V,C[P+4],S,4118548399);V=u(V,Y,X,W,C[P+5],Q,1200080426);W=u(W,V,Y,X,C[P+6],N,2821735955);X=u(X,W,V,Y,C[P+7],M,4249261313);Y=u(Y,X,W,V,C[P+8],S,1770035416);V=u(V,Y,X,W,C[P+9],Q,2336552879);W=u(W,V,Y,X,C[P+10],N,4294925233);X=u(X,W,V,Y,C[P+11],M,2304563134);Y=u(Y,X,W,V,C[P+12],S,1804603682);V=u(V,Y,X,W,C[P+13],Q,4254626195);W=u(W,V,Y,X,C[P+14],N,2792965006);X=u(X,W,V,Y,C[P+15],M,1236535329);Y=f(Y,X,W,V,C[P+1],A,4129170786);V=f(V,Y,X,W,C[P+6],z,3225465664);W=f(W,V,Y,X,C[P+11],y,643717713);X=f(X,W,V,Y,C[P+0],w,3921069994);Y=f(Y,X,W,V,C[P+5],A,3593408605);V=f(V,Y,X,W,C[P+10],z,38016083);W=f(W,V,Y,X,C[P+15],y,3634488961);X=f(X,W,V,Y,C[P+4],w,3889429448);Y=f(Y,X,W,V,C[P+9],A,568446438);V=f(V,Y,X,W,C[P+14],z,3275163606);W=f(W,V,Y,X,C[P+3],y,4107603335);X=f(X,W,V,Y,C[P+8],w,1163531501);Y=f(Y,X,W,V,C[P+13],A,2850285829);V=f(V,Y,X,W,C[P+2],z,4243563512);W=f(W,V,Y,X,C[P+7],y,1735328473);X=f(X,W,V,Y,C[P+12],w,2368359562);Y=D(Y,X,W,V,C[P+5],o,4294588738);V=D(V,Y,X,W,C[P+8],m,2272392833);W=D(W,V,Y,X,C[P+11],l,1839030562);X=D(X,W,V,Y,C[P+14],j,4259657740);Y=D(Y,X,W,V,C[P+1],o,2763975236);V=D(V,Y,X,W,C[P+4],m,1272893353);W=D(W,V,Y,X,C[P+7],l,4139469664);X=D(X,W,V,Y,C[P+10],j,3200236656);Y=D(Y,X,W,V,C[P+13],o,681279174);V=D(V,Y,X,W,C[P+0],m,3936430074);W=D(W,V,Y,X,C[P+3],l,3572445317);X=D(X,W,V,Y,C[P+6],j,76029189);Y=D(Y,X,W,V,C[P+9],o,3654602809);V=D(V,Y,X,W,C[P+12],m,3873151461);W=D(W,V,Y,X,C[P+15],l,530742520);X=D(X,W,V,Y,C[P+2],j,3299628645);Y=t(Y,X,W,V,C[P+0],U,4096336452);V=t(V,Y,X,W,C[P+7],T,1126891415);W=t(W,V,Y,X,C[P+14],R,2878612391);X=t(X,W,V,Y,C[P+5],O,4237533241);Y=t(Y,X,W,V,C[P+12],U,1700485571);V=t(V,Y,X,W,C[P+3],T,2399980690);W=t(W,V,Y,X,C[P+10],R,4293915773);X=t(X,W,V,Y,C[P+1],O,2240044497);Y=t(Y,X,W,V,C[P+8],U,1873313359);V=t(V,Y,X,W,C[P+15],T,4264355552);W=t(W,V,Y,X,C[P+6],R,2734768916);X=t(X,W,V,Y,C[P+13],O,1309151649);Y=t(Y,X,W,V,C[P+4],U,4149444226);V=t(V,Y,X,W,C[P+11],T,3174756917);W=t(W,V,Y,X,C[P+2],R,718787259);X=t(X,W,V,Y,C[P+9],O,3951481745);Y=K(Y,h);X=K(X,E);W=K(W,v);V=K(V,g)}var i=B(Y)+B(X)+B(W)+B(V);return i.toLowerCase()};

  var cookies = {};
  var i,x,y,ARRcookies=document.cookie.split(";");
  for (i=0;i<ARRcookies.length;i++) {
    x=ARRcookies[i].substr(0,ARRcookies[i].indexOf("="));
    y=ARRcookies[i].substr(ARRcookies[i].indexOf("=")+1);
    x=x.replace(/^\s+|\s+$/g,"");
    try{ cookies[x]=decodeURIComponent(y); }catch(x){};
  };

  // define window.console unless JS engine defines it
  if (!window.console) window.console = {log: function() {}};

  function getCookie(c_name, defaultValue) {
    if (c_name in cookies) return cookies[c_name];
    return defaultValue;
  }

  function setCookie(c_name,value, days, minutes){
    if (typeof(value)=='undefined' || ! value){
      document.cookie = encodeURIComponent(c_name) + "=deleted; expires=" + new Date(0).toUTCString()+"; path=/";
      document.cookie = encodeURIComponent(c_name) + "=deleted; expires=" + new Date(0).toUTCString()+"; path=/; domain=." + config.domain;
      delete cookies[c_name];
    } else {
      var exdate = new Date();
      if (!days && !minutes) {days = 365;}
      if (days) {exdate.setDate(exdate.getDate() + days);}
      if (minutes) {exdate.setMinutes( exdate.getMinutes() + minutes);}
      document.cookie = c_name + "=" + encodeURIComponent(value) + "; expires=" + exdate.toUTCString() + "; path=/" + (isProduction ? "; domain=." + config.domain : "");
      cookies[c_name] = value;
    }
  }

  var trackingCodes = getCookie("trackingCodes") ? JSON.parse(getCookie("trackingCodes")) : false;

  var trackEvent = function trackEvent(name, data, callback) {
  };

  return {
    config: config,
    baseURL: location.protocol + "//" + location.hostname + (location.port && ":" + location.port),
    trackingCodes: trackingCodes,
    trackEvent: trackEvent,
    MD5: MD5,
    cookies: cookies,
  }
})();

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

  var hashtag = VZ.config.twitter.hashtag;
  var hashtags = VZ.config.twitter.hashtags;
  var tweetPrefix = "Check out what I found on VOYZ.ES ";

  var setupTwitter = function setupTwitter(tweetURL, openAfterSetup) {
    if (!('isTweetURLSet' in this)) {this.isTweetURLSet = false;}
    if (!tweetURL && this.isTweetURLSet) {return;}
    var url = VZ.baseURL + (tweetURL ? tweetURL : document.location.pathname);
    var title = $('head meta[property="og:title"]').attr("content") || "";
    var image = $('head meta[property="og:image"]').attr("content");

    if (trackingCodes && ('twitter' in trackingCodes)) url += "?r=" + trackingCodes.twitter;
    var href = 'https://twitter.com/intent/tweet?related=' + hashtag + '&url=' + encodeURIComponent(url) + '&text=' + encodeURIComponent(tweetPrefix + title) + '&hashtags=' + encodeURIComponent(hashtags);
    $('.social-networks .twitter a').attr("data-href", href);
    this.isTweetURLSet = true;

    if (openAfterSetup) {
      window.open(href, '', 'height=600,width=500');
    } else {
      $('.social-networks .twitter a').click(function(e) {
        e.preventDefault();
        window.open(href, '', 'height=600,width=500');
      });
    }
  }

  var bind = function bind() {
    // facebook
    $('.social-networks .facebook a').attr("href",'http://www.facebook.com/sharer/sharer.php?u=' + encodeURIComponent(url))
    .on('click', function(e) {
      var href = this.getAttribute('data-href'),
        fburl = decodeURIComponent(href.substring(href.indexOf("u=") + 2));

      if (trackingCodes && ('facebook' in trackingCodes)) {
        href += "%3Fr%3D" + trackingCodes.facebook;
      }
      window.open(href, 'sharer', "toolbar=no,menubar=no,scrollbars=no,location=no,directories=no,width=626,height=300");
      VZ.trackEvent("facebook-button-clicked", {url : fburl});
      return false;
    });

    // twitter
    setupTwitter();
    $('.social-networks .twitter a').on('click', function(e) {
      e.preventDefault();
      var href = this.getAttribute('data-href');
      var product_title = encodeURIComponent(href.substring( $(this).attr('data-product-title')));
      var tw_url = decodeURIComponent(href.substring(href.lastIndexOf("url=") + 4));
      if (trackingCodes && ('twitter' in trackingCodes)) {
        tw_url += "?r=" + trackingCodes.twitter;
      }
      href = 'https://twitter.com/intent/tweet?related=dotandbo&url='+encodeURIComponent(tw_url)+'&text='+encodeURIComponent(tweetPrefix)+'&hashtags='+encodeURIComponent(hashtags);
      window.open(href, '', 'height=500,width=450');
      VZ.trackEvent("twitter-button-clicked", {url : tw_url});
    });

  };

  $(function() {
    bind();
  });

  VZ.social = {twitter: {}};
  VZ.social.bind = bind;
  VZ.social.twitter.hashtag = hashtag;
  VZ.social.twitter.setup = setupTwitter;
  // VZ.social.hashtag = hashtag;
})();

$.extend(true, $.notify.defaultOptions, {
  "align": "center",
  "offset": {
    "from": "top"
  },
  "delay": 1500,
  "type": "warning"
});

$.extend({
  /*
   *  E.g. $.alert("This is an error!", {"title": "error"});
   */
  alert: function(text, options) {
    options = _.extend(options || {}, {});
    var title = options.title || "";

    var html = '<div id="alert-modal" class="modal fade alert-modal bs-example-modal-sm">' +
      '<div class="modal-dialog">' +
        '<div class="modal-content">' +
          (!!title ?
          '<div class="modal-header">' +
            '<button type="button" class="close" data-dismiss="modal"><span aria-hidden="true">&times;</span><span class="sr-only">Close</span></button>' +
            '<h4 class="modal-title">' + title + '</h4>' +
          '</div>' : '') +
          '<div class="modal-body">' +
            '<p>' + text + '</p>' +
          '</div>' +
          '<div class="modal-footer">' +
            '<button type="button" class="btn btn-primary" data-dismiss="modal">Ok</button>' +
          '</div>' +
        '</div><!-- /.modal-content -->' +
      '</div><!-- /.modal-dialog -->' +
    '</div><!-- /.modal -->';

    $("#alert-modal").remove();
    $('body').append(html);
    $('#alert-modal').modal();
  },

  /*
   *  E.g. $.confirm("This is an error!", function(result) { result ? true : false });
   */
  confirm: function(text, callback) {
    var title;
    //options = _.extend(options || {}, {});

    var html = '<div id="confirm-modal" class="modal fade confirm-modal bs-example-modal-sm">' +
      '<div class="modal-dialog">' +
        '<div class="modal-content">' +
          (!!title ?
          '<div class="modal-header">' +
            '<button type="button" class="close" data-dismiss="modal"><span aria-hidden="true">&times;</span><span class="sr-only">Close</span></button>' +
            '<h4 class="modal-title">' + title + '</h4>' +
          '</div>' : "" ) +
          '<div class="modal-body">' +
            '<p>' + text + '</p>' +
          '</div>' +
          '<div class="modal-footer">' +
            '<button type="button" class="btn btn-default btn-cancel" data-dismiss="modal">Cancel</button>' +
            '<button type="button" class="btn btn-primary btn-ok" data-dismiss="modal">OK</button>' +
          '</div>' +
        '</div><!-- /.modal-content -->' +
      '</div><!-- /.modal-dialog -->' +
    '</div><!-- /.modal -->';

    $("#confirm-modal").remove();
    $('body').append(html);
    $('#confirm-modal').modal({

    });
    $("#confirm-modal .btn-ok").bind("click", function() {
      callback(true);
    });
    $("#confirm-modal .btn-cancel").bind("click", function() {
      callback(false);
    });
  }
});
