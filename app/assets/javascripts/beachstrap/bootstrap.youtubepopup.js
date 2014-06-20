/*!
 * Bootstrap YouTube Popup Player Plugin
 * http://lab.abhinayrathore.com/bootstrap-youtube/
 * https://github.com/abhinayrathore/Bootstrap-Youtube-Popup-Player-Plugin
 */
(function ($) {
    var $YouTubeModal       = null,
        $YouTubeModalDialog = null,
        $YouTubeModalTitle  = null,
        $YouTubeModalBody   = null,
        margin              = 1;

    //Plugin methods
    var methods = {
        //initialize plugin
        init: function (options) {
            options = $.extend({}, $.fn.YouTubeModal.defaults, options);

            // initialize YouTube Player Modal
            if ($YouTubeModal == null) {
                $YouTubeModal = $('<div class="modal fade' + options.cssClass + '" id="YouTubeModal" role="dialog" aria-hidden="true">');
                var modalContent = '<div class="modal-dialog" id="YouTubeModalDialog">'+
                    '<div class="modal-content" id="YouTubeModalContent">'+
                      '<div class="modal-header">'+
                        '<button type="button" class="close" data-dismiss="modal">&times;</button>'+
                        '<h4 class="modal-title" id="YouTubeModalTitle"></h4>'+
                      '</div>'+
                      '<div class="modal-body" id="YouTubeModalBody" style="padding:0;"></div>'+
                    '</div>'+
                  '</div>';
                $YouTubeModal.html(modalContent).hide().appendTo('body');
                $YouTubeModalDialog = $("#YouTubeModalDialog");
                $YouTubeModalTitle = $("#YouTubeModalTitle");
                $YouTubeModalBody = $("#YouTubeModalBody");
                $YouTubeModal.modal({
                    show: false
                }).on('hide.bs.modal', resetModalBody)
                  .on('show.bs.modal', function () {
                    $(this).find('.modal-body').css({
                      width:'auto',  // probably not needed
                      height:'auto', // probably not needed 
                      'max-height':'100%'
                    });
                  });
            }

            return this.each(function () {
                var obj = $(this);
                var data = obj.data('YouTube');
                if (!data) { //check if event is already assigned
                    obj.data('YouTube', {
                        target: obj
                    });
                    $(obj).bind('click.YouTubeModal', function () {
                        var youtubeId = options.youtubeId;
                        if ($.trim(youtubeId) == '' && obj.is("a")) {
                            youtubeId = getYouTubeIdFromUrl(obj.attr("href"));
                        }
                        if ($.trim(youtubeId) == '' || youtubeId === false) {
                            youtubeId = obj.attr(options.idAttribute);
                        }
                        var videoTitle = $.trim(options.title);
                        if (videoTitle == '') {
                            if (options.useYouTubeTitle) setYouTubeTitle(youtubeId);
                            else videoTitle = obj.attr('title');
                        }
                        if (videoTitle) {
                            setModalTitle(videoTitle);
                        }

                        resizeModal(options.width);

                        //Setup YouTube Modal
                        var YouTubeURL = getYouTubeUrl(youtubeId, options);
                        var YouTubePlayerIframe = getYouTubePlayer(YouTubeURL, options.width, options.height);
                        
                        setModalBody(YouTubePlayerIframe);
                        
/*
                        $("#YouTubeModal iframe").each(function() {
                          $(this).data('aspectRatio', this.height / this.width)
                            .removeAttr('height')
                            .removeAttr('width');
                        });

                        $(window).resize(function() {
                          var newWidth = $("body").width() * .5;

                          // Resize all videos according to their own aspect ratio
                          $("#YouTubeModal .modal-body").each(function() {
                            var $el = $(this);
                            $el
                              .width(newWidth)
                              .height(newWidth * $el.find("iframe").data('aspectRatio'));
                          });
                        }).resize();
*/

                        $YouTubeModal.modal('show');
                        return false;
                    });
                }
            });
        },
        destroy: function () {
            return this.each(function () {
                $(this).unbind(".YouTubeModal").removeData('YouTube');
            });
        }
    };

    function setModalTitle(title) {
        $YouTubeModalTitle.html($.trim(title));
    }

    function setModalBody(content) {
        $YouTubeModalBody.html("<div class='video-wrapper'>" + content + "</div>");
    }

    function resetModalBody() {
        setModalTitle('');
        setModalBody('');
    }

    function resizeModal(w) {
        $YouTubeModalDialog.css({
            width: w + (margin * 2)
        });
    }

    function getYouTubeUrl(youtubeId, options) {
        var YouTubeURL = "//www.youtube.com/embed/" + youtubeId + "?rel=0&showsearch=0&autohide=" + options.autohide;
        YouTubeURL += "&autoplay=" + options.autoplay + "&controls=" + options.controls + "&fs=" + options.fs + "&loop=" + options.loop;
        YouTubeURL += "&showinfo=" + options.showinfo + "&color=" + options.color + "&theme=" + options.theme;
        YouTubeURL += "&wmode=transparent"; // Firefox Bug Fix
        return YouTubeURL;
    }

    function getYouTubePlayer(URL, width, height) {
        var YouTubePlayer = '<iframe title="YouTube video player" width="' + width + '" height="' + height + '" ';
        YouTubePlayer += 'style="margin:0; padding:0; box-sizing:border-box; border:0; -webkit-border-radius:5px; -moz-border-radius:5px; border-radius:5px; margin:' + (margin - 1) + 'px;" ';
        YouTubePlayer += 'src="' + URL + '" frameborder="0" allowfullscreen seamless></iframe>';
        return YouTubePlayer;
    }

    function setYouTubeTitle(youtubeId) {
        var url = "https://gdata.youtube.com/feeds/api/videos/" + youtubeId + "?v=2&alt=json";
        $.ajax({
            url: url,
            dataType: 'jsonp',
            cache: true,
            success: function (data) {
                setModalTitle(data.entry.title.$t);
            }
        });
    }

    function getYouTubeIdFromUrl(youtubeUrl) {
        var regExp = /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=)([^#\&\?]*).*/;
        var match = youtubeUrl.match(regExp);
        if (match && match[2].length == 11) {
            return match[2];
        } else {
            return false;
        }
    }

    $.fn.YouTubeModal = function (method) {
        if (methods[method]) {
            return methods[method].apply(this, Array.prototype.slice.call(arguments, 1));
        } else if (typeof method === 'object' || !method) {
            return methods.init.apply(this, arguments);
        } else {
            $.error('Method ' + method + ' does not exist on Bootstrap.YouTubeModal');
        }
    };

    //default configuration
    $.fn.YouTubeModal.defaults = {
        youtubeId: '',
        title: '',
        useYouTubeTitle: true,
        idAttribute: 'rel',
        cssClass: 'YouTubeModal',
        width: 640,
        height: 480,
        autohide: 2,
        autoplay: 1,
        color: 'red',
        controls: 1,
        fs: 1,
        loop: 0,
        showinfo: 0,
        theme: 'light'
    };
})(jQuery);