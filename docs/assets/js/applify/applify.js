(function($, undefined) {
    "use strict";
    var doc = $(document), body = $("body"), win = $(window), breaks = {
        xs: 576,
        sm: 768,
        md: 992,
        lg: 1200
    };
    $.fn.ui_navbar = function() {
        var navbar = this;
        var toggle = $(".ui-mobile-nav-toggle");
        var navbar_nav = $(".ui-navigation");
        win.scroll(function() {
            var scroll_top = $(this).scrollTop();
            if (body.hasClass("ui-transparent-nav") && !body.hasClass("mobile-nav-active")) {
                if (scroll_top >= 24) {
                    navbar.removeClass("transparent");
                } else {
                    navbar.addClass("transparent");
                }
            }
        });
        toggle.html("<div><span></span><span></span><span></span><span></span></div>");
        var toggle_nav = function() {
            var win_top = win.scrollTop();
            if (!body.hasClass("mobile-nav-active")) {
                body.addClass("mobile-nav-active");
                toggle.addClass("active");
                navbar_nav.slideDown(250, function() {
                    navbar_nav.find("li").animate({
                        opacity: 1
                    }, 350);
                });
                if (body.hasClass("ui-transparent-nav")) {
                    navbar.removeClass("transparent");
                }
            } else {
                body.removeClass("mobile-nav-active");
                toggle.removeClass("active");
                navbar_nav.find("li").animate({
                    opacity: 0
                }, 100, function() {
                    navbar_nav.slideUp(200);
                });
                if (body.hasClass("ui-transparent-nav")) {
                    if (win_top < 24) {
                        navbar.addClass("transparent");
                    }
                }
            }
        };
        toggle.on("click", function(e) {
            e.preventDefault();
            toggle_nav();
        });
        win.resize(function() {
            var w = $(this).width();
            var win_top = win.scrollTop();
            if (w >= breaks.md) {
                navbar_nav.find("li").css({
                    opacity: 1
                });
                if (body.hasClass("mobile-nav-active")) {
                    body.removeClass("mobile-nav-active");
                    toggle.removeClass("active");
                    if (body.hasClass("ui-transparent-nav")) {
                        if (win_top < 24) {
                            navbar.addClass("transparent");
                        }
                    }
                }
                navbar_nav.show();
            } else {
                if (!body.hasClass("mobile-nav-active")) {
                    navbar_nav.hide();
                }
                navbar_nav.find("[data-scrollto]").on("click", function() {
                    navbar_nav.hide();
                });
            }
            if (w >= breaks.md) {
                navbar_nav.insertAfter(".navbar-brand");
            } else {
                navbar_nav.appendTo(navbar);
            }
            $(".ui-variable-logo").css({
                width: $(".ui-variable-logo img").width() + 32 + "px"
            });
        });
    };
    $.fn.ui_hero_slider = function() {
        var ui_slider = this;
        var slider_height = ui_slider.find(".container").outerHeight();
        ui_slider.find(".sp-slides").css({
            height: slider_height + "px"
        });
        var fade_enabled = ui_slider.data("fade");
        var touch_enabled = ui_slider.data("touch_swipe");
        var autoplay_enabled = ui_slider.data("auto_play");
        var autoplay_delay = ui_slider.data("autoplay_delay");
        var autoplay_on_hover = ui_slider.data("autoplay_on_hover");
        var show_dots = ui_slider.data("show_dots");
        var show_arrows = ui_slider.data("show_arrows");
        ui_slider.sliderPro({
            width: "100%",
            height: "100%",
            autoHeight: true,
            fade: fade_enabled,
            touchSwipe: touch_enabled,
            arrows: show_arrows,
            buttons: show_dots,
            autoplay: autoplay_enabled,
            autoplayDelay: autoplay_delay,
            autoplayOnHover: autoplay_on_hover,
            waitForLayers: true,
            fadeOutPreviousSlide: true,
            fadeDuration: 1e3,
            autoScaleLayers: false,
            init: function() {
                setTimeout(function() {
                    ui_slider.find(".sp-slides").removeClass("fade");
                }, 1e3);
            }
        });
        win.on("focus", function() {
            ui_slider.sliderPro("nextSlide");
        });
    };
    $.fn.ui_app_showcase = function() {
        var showcase = this;
        var col_txt_a = this.find('[data-col="text_a"]').get(0).outerHTML;
        var col_txt_b = this.find('[data-col="text_b"]').get(0).outerHTML;
        var col_img = this.find('[data-col="img"]').get(0).outerHTML;
        win.on("resize", function() {
            if ($(this).width() >= breaks.sm) {
                showcase.html(col_txt_a + col_img + col_txt_b);
            } else {
                showcase.html(col_img + '<div class="col-xs-8" data-vertical_center="true"><div class="row">' + col_txt_a + col_txt_b + "</div></div>");
            }
        });
    };
    $.fn.ui_app_screens = function() {
        this.owlCarousel({
            center: true,
            loop: true,
            margin: 16,
            autoWidth: true
        });
    };
    $.fn.ui_device_slider = function() {
        var id = this.attr("id");
        var items = this.find(".item").length;
        var z = false;
        var y = false;
        var owl = this.owlCarousel({
            loop: true,
            margin: 0,
            nav: false,
            dots: true,
            items: 1,
            autoWidth: true
        });
        owl.on("changed.owl.carousel", function(event) {
            z = true;
            if (!y) {
                var slide = event.relatedTarget.normalize(event.item.index, true) - 2;
                if (slide < 0) {
                    slide = items + slide + 1;
                } else {
                    slide = slide + 1;
                }
                $('[data-toggle_slider="' + id + '"][data-toggle_screen="' + slide + '"]').trigger("click");
            }
            z = false;
        });
        $('[data-toggle_slider="' + id + '"][data-toggle_screen]').on("click", function() {
            y = true;
            if (!z) {
                var i = $(this).data("toggle_screen") - 1;
                owl.trigger("to.owl.carousel", i);
            }
            y = false;
        });
    };
    $.fn.ui_pricing_cards = function() {
        var cards = this;
        cards.owlCarousel({
            loop: false,
            margin: 0,
            nav: true,
            responsive: {
                0: {
                    items: 1
                },
                740: {
                    items: 3
                }
            }
        });
        function to_active_card() {
            cards.trigger("to.owl.carousel", 1);
        }
        var z;
        win.on("resize", function() {
            clearTimeout(z);
            z = setTimeout(to_active_card, 500);
        });
    };
    $.fn.ui_testimonials = function() {
        this.owlCarousel({
            loop: true,
            margin: 16,
            nav: true,
            responsive: {
                0: {
                    items: 1
                },
                740: {
                    items: 2
                },
                992: {
                    items: 3
                }
            }
        });
    };
    $.fn.ui_stats = function() {
        var stats = this;
        var stat = stats.find(".stat");
        var duration = stats.data("duration");
        var counted = false;
        win.scroll(function() {
            if (stats.isOnScreen()) {
                if (!counted) {
                    count();
                }
                counted = true;
            }
        });
        function count() {
            stat.each(function() {
                $(this).prop("Counter", 0).animate({
                    Counter: $(this).text()
                }, {
                    duration: duration,
                    easing: "swing",
                    step: function(now) {
                        $(this).text(Math.ceil(now));
                    }
                });
            });
        }
    };
    $.fn.ui_accordion = function() {
        var el = this;
        var accordion = el.find(".ui-accordion");
        var accordion_toggle = el.find(".toggle");
        var accordion_body = el.find(".body");
        accordion.first().addClass("active");
        accordion_body.first().css("display", "block");
        accordion_toggle.on("click", function(e) {
            e.preventDefault();
            var toggle = $(this).data("toggle");
            var target = $('.body[data-accord="' + toggle + '"]');
            $(this).closest(".ui-accordion").addClass("active");
            target.slideDown(250);
            target.children().animate({
                opacity: 1
            }, 750);
            accordion_body.not(target).closest(".ui-accordion").removeClass("active");
            accordion_body.not(target).slideUp(250);
            accordion_body.not(target).children().animate({
                opacity: 0
            }, 150);
        });
    };
    $.fn.modal = function() {
        doc.on("click", '[data-close="modal"]', function() {
            var m = $(this).closest(".modal");
            closeModal(m);
        });
        doc.on("click", ".modal", function(e) {
            if (e.target === this) {
                closeModal($(this));
            }
        });
        function closeModal(m) {
            body.removeClass("modal-open");
            m.fadeOut(250, function() {
                doc.trigger("modal-hidden");
            });
        }
        return {
            show: function(modal) {
                modal.fadeIn(250);
                body.addClass("modal-open");
            },
            hide: function(modal) {
                closeModal(modal);
            }
        };
    };
    var ui_modal = doc.modal();
    $.fn.ui_video_player = function() {
        var video_modal = $('<div class="video-modal modal" role="dialog"><div class="dialog container"><a class="close" data-close="modal" aria-hidden="true">×</a><div class="video-player"></div></div></div>');
        var toggle = this;
        toggle.on("click", function() {
            var youtube_id = $(this).data("video");
            body.append(video_modal);
            $(".video-modal").find(".video-player").html('<div class="video-player"><iframe src="https://www.youtube-nocookie.com/embed/' + youtube_id + '?rel=0&amp;showinfo=0&amp;autoplay=1" frameborder="0" allowfullscreen></iframe></div>');
            ui_modal.show($(".video-modal"));
        });
        doc.on("modal-hidden", function() {
            $(".video-modal").remove();
        });
    };
    $.fn.ui_collapsible_nav = function() {
        var cnav_toggle = this.find("a.toggle");
        var collapsible = {
            show: function(e) {
                e.slideDown(250);
            },
            hide: function(e) {
                e.slideUp(250);
            }
        };
        cnav_toggle.on("click", function(e) {
            e.preventDefault();
            var a = $(this);
            var ul = a.next();
            var sibs = a.parent().siblings();
            var sibs_togg = sibs.children(".toggle");
            if (!a.hasClass("active")) {
                if (sibs_togg.length) {
                    sibs_togg.removeClass("active");
                    collapsible.hide(sibs_togg.next("ul"));
                }
                collapsible.show(ul);
                a.addClass("active");
            } else {
                collapsible.hide(ul);
                a.removeClass("active");
            }
        });
        cnav_toggle.each(function() {
            var togg = $(this);
            if (togg.hasClass("active")) {
                collapsible.show(togg.next("ul"));
            } else {
                collapsible.hide(togg.next("ul"));
            }
        });
    };
    $.fn.ui_instagram_feed = function() {
        var valid = true;
        var gram = this;
        var auth_token = gram.data("authtoken");
        var user_id = gram.data("userid");
        var max_items = gram.data("items");
        if (auth_token === "YOUR_AUTHTOKEN" || auth_token.length === 0) {
            console.error('Instgram Widget: - You need to place your auth token in the widget\'s "data-authtoken" attribute.');
            valid = false;
        }
        if (user_id === "YOUR_USERID" || user_id.length === 0) {
            console.error('Instgram Widget: - You need to place your user id in the widget\'s "data-userid" attribute .');
            valid = false;
        }
        if (valid) {
            $.ajax({
                url: "https://api.instagram.com/v1/users/" + user_id + "/media/recent",
                dataType: "jsonp",
                type: "GET",
                data: {
                    access_token: auth_token,
                    count: max_items
                },
                success: function(data) {
                    var x;
                    for (x in data.data) {
                        gram.append('<a href="' + data.data[x].link + '" target="_blank"><img src="' + data.data[x].images.standard_resolution.url + '"></a>');
                    }
                },
                error: function(data) {
                    console.error("Instagram Widget Error: " + data);
                }
            });
        }
    };
    $.fn.ui_scroll_to = function() {
        var link = $("[data-scrollto]");
        link.on("click", function(e) {
            e.preventDefault();
            var scroll_to = $(this).attr("data-scrollto");
            if ($("#" + scroll_to + ".section").length > 0 && scroll_to !== undefined) {
                var pos = $("#" + scroll_to).offset().top;
                $("html, body").animate({
                    scrollTop: pos
                }, 500, function() {
                    window.location.hash = scroll_to;
                });
            }
        });
    };
    $.fn.ui_action_card = function() {
        var card = this;
        card.on("click", function() {
            window.location.href = $(this).data("target");
        });
    };
    $.fn.ui_uhd_images = function() {
        var img = this;
        var total = img.length;
        var loaded = 0;
        if (window.devicePixelRatio >= 1.25) {
            setUHDImage(img);
        }
        function setUHDImage(images) {
            images.each(function() {
                loaded++;
                var this_img = $(this);
                var img_src = this_img.attr("src");
                if (typeof img_src !== "undefined") {
                    var img_type = img_src.split(".").pop();
                    var retina_img = img_src.replace("." + img_type, "@2x." + img_type);
                    this_img.attr("src", retina_img);
                    if (loaded >= total) {
                        setTimeout(function() {
                            doc.trigger("images_did_load");
                        }, 500);
                    }
                }
            });
        }
    };
    load_bg_images();
    function load_bg_images() {
        var images = doc.find("[data-bg]");
        var uhd = doc.find("[data-uhd][data-bg]");
        if (window.devicePixelRatio >= 1.25) {
            uhd.each(function() {
                var this_img = $(this);
                var img_src = this_img.attr("data-bg");
                var img_type = img_src.split(".").pop();
                var retina_img = img_src.replace("." + img_type, "@2x." + img_type);
                this_img.css({
                    "background-image": "url('" + retina_img + "')"
                });
            });
        } else {
            images.each(function() {
                var this_img = $(this);
                var img_src = this_img.attr("data-bg");
                this_img.css({
                    "background-image": "url('" + img_src + "')"
                });
            });
        }
    }
    images_loaded();
    function images_loaded() {
        var images = doc.find("img");
        var total = images.length;
        var loaded = 0;
        var dummy = $("<img/>");
        images.each(function() {
            var img_src = $(this).attr("src");
            dummy.attr("src", img_src).on("load", function() {
                loaded++;
                if (loaded >= total) {
                    setTimeout(function() {
                        doc.trigger("images_did_load");
                    }, 300);
                }
            });
        });
    }
    $("[data-max_width]").each(function() {
        $(this).css({
            "max-width": $(this).attr("data-max_width") + "px"
        });
    });
    $.fn.isOnScreen = function() {
        var viewport = {
            top: win.scrollTop()
        };
        viewport.bottom = viewport.top + win.height();
        var bounds = this.offset();
        bounds.bottom = bounds.top + this.outerHeight();
        var winWidth = win.width();
        if (winWidth > breaks.lg) {
            return !(viewport.bottom < bounds.top + 200 || viewport.top > bounds.bottom + 60);
        } else {
            return !(viewport.bottom < bounds.top + 20 || viewport.top > bounds.bottom + 20);
        }
    };
    win.scroll(function() {
        $("[data-show]").not(".animated").each(function() {
            var el = $(this);
            var show_animation = $(this).attr("data-show");
            var animation_delay = $(this).attr("data-delay");
            if (el.isOnScreen()) {
                if (!animation_delay) {
                    el.addClass(show_animation);
                } else {
                    setTimeout(function() {
                        el.addClass(show_animation);
                    }, animation_delay);
                }
                el.addClass("animated");
            }
        });
    });
    if ($("form#contact-form").length > 0) {
        $.validate({
            form: "form#contact-form",
            validateOnBlur: true,
            modules: "sanitize",
            scrollToTopOnError: false,
            onSuccess: function($form) {
                submit_form($form, "mailer/submit-contact-form.php");
                return false;
            }
        });
    }
    if ($("form#sign-up-form").length > 0) {
        $.validate({
            form: "form#sign-up-form",
            validateOnBlur: true,
            modules: "sanitize",
            scrollToTopOnError: false,
            onSuccess: function($form) {
                submit_form($form, "mailer/submit-subscribe-form.php");
                return false;
            }
        });
    }
    function submit_form(form, script) {
        var the_form = form;
        the_form.find("button").text("Sending");
        var form_data = {};
        $.each(the_form.serializeArray(), function() {
            form_data[this.name] = this.value;
        });
        var form_json = JSON.stringify(form_data);
        $.ajax({
            url: script,
            async: true,
            cache: false,
            type: "POST",
            dataType: "json",
            data: {
                data: form_json
            },
            success: function(data) {
                if (data.status === "success") {
                    the_form.trigger("reset");
                    the_form.find("button").text("Sent");
                    var msg = $('<span class="help-block form-success" style="margin-bottom: 0;margin-top: 1rem"/>').text(data.message);
                    if ($("#contact-form").length > 0) {
                        msg = $('<span class="help-block form-success" style="margin-bottom: 1rem;margin-top: 1rem"/>').text(data.message);
                        msg.insertBefore(the_form.find("button"));
                    } else {
                        the_form.append(msg);
                    }
                } else if (data.status === "error") {
                    console.error("Error: " + data.message);
                }
            },
            error: function() {
                console.error("Error: Ajax Fatal Error");
            }
        });
    }
    if ($(".ui-turncate-text").length) {
        var txtElements = $(".ui-turncate-text");
        var resizeThreshold2;
        txtElements.each(function() {
            var el = $(this);
            var originalText = el.children("p").text();
            win.on("resize", function() {
                clearTimeout(resizeThreshold2);
                resizeThreshold2 = setTimeout(function() {
                    el.children("p").text(originalText);
                }, 200);
                resizeThreshold2 = setTimeout(function() {
                    txtElements.dotdotdot();
                }, 250);
            });
        });
    }
    if ($(".ui-logos-cloud").length) {
        var cloud_wrapper = $(".ui-logos-cloud");
        var logos = cloud_wrapper.children();
        logos.each(function() {
            var el = $(this);
            var size = el.attr("data-size");
            el.css({
                width: 10 * size + "px",
                height: 10 * size + "px"
            });
        });
    }
    win.on("scroll", function() {
        var cur_pos = $(this).scrollTop();
        $(".section").each(function() {
            var section = $(this);
            var section_id = $(this).attr("id");
            var top = section.offset().top - 60, bottom = top + section.outerHeight();
            if (cur_pos >= top && cur_pos <= bottom) {
                $('[data-scrollto="' + section_id + '"]').parent().addClass("active").siblings().removeClass("active");
            } else {
                $('[data-scrollto="' + section_id + '"]').parent().removeClass("active");
            }
        });
    });
    win.on("resize", function() {
        if (win.width() >= 740) {
            $(".pricing-sidebar .pricing-header").height($(".pricing-block .pricing-header").outerHeight());
        } else {
            $(".pricing-sidebar .pricing-header").height("auto");
        }
    });
    $(".price-toggle").on("click", function() {
        var btn = $(this);
        var target = btn.attr("data-toggle");
        var btn_class = btn.attr("class");
        var sibling_class = btn.siblings().attr("class");
        btn.attr("class", sibling_class);
        btn.siblings().attr("class", btn_class);
        if (target === "monthly_price") {
            $(".price-wrapper[data-price_mo]").each(function() {
                var price = $(this).attr("data-price_mo");
                var price_arr = price.split(".");
                $(this).children(".price").text(price_arr[0]);
                $(this).children(".price-postfix").text("." + price_arr[1]);
            });
        } else {
            $(".price-wrapper[data-price_ann]").each(function() {
                var price = $(this).attr("data-price_ann");
                var price_arr = price.split(".");
                $(this).children(".price").text(price_arr[0]);
                $(this).children(".price-postfix").text("." + price_arr[1]);
            });
        }
    });
    $(".navbar").ui_navbar();
    if ($("[data-uhd]").length) {
        $("[data-uhd]").ui_uhd_images();
    }
    if ($("[data-scrollto]").length) {
        $("[data-scrollto]").ui_scroll_to();
    }
    if ($(".ui-hero-slider").length) {
        $(".ui-hero-slider").ui_hero_slider();
    }
    if ($(".ui-app-showcase").length) {
        $(".ui-app-showcase").ui_app_showcase();
    }
    if ($(".ui-accordion-panel").length) {
        $(".ui-accordion-panel").each(function() {
            $(this).ui_accordion();
        });
    }
    if ($(".ui-device-slider").length) {
        $(".ui-device-slider .screens").each(function() {
            $(this).ui_device_slider();
        });
    }
    if ($(".ui-pricing-cards").length) {
        $(".ui-pricing-cards").ui_pricing_cards();
    }
    if ($(".ui-testimonials").length) {
        $(".ui-testimonials").ui_testimonials();
    }
    if ($(".ui-stats").length) {
        $(".ui-stats").ui_stats();
    }
    if ($(".ui-app-screens").length) {
        $(".ui-app-screens").ui_app_screens();
    }
    if ($(".ui-video-toggle").length) {
        $(".ui-video-toggle").ui_video_player();
    }
    if ($(".ui-collapsible-nav").length) {
        doc.ui_collapsible_nav();
    }
    if ($(".ui-action-card").length) {
        $(".ui-action-card").ui_action_card();
    }
    if ($(".ui-instagram-widget .insta-feed").length) {
        $(".ui-instagram-widget .insta-feed").ui_instagram_feed();
    }
    win.trigger("scroll");
    win.trigger("resize");
    doc.imagesLoaded(function() {
        win.trigger("resize");
        $('[data-fade_in="on-load"]').animate({
            opacity: 1
        }, 450);
    });
})(jQuery);