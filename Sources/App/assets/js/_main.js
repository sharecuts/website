'use strict';

$(function() {

  ScrollReveal({ container: '.main' }).reveal('.card');

  // $('.card-deck').slick({
  //   arrows: true,
  //   prevArrow: '<button class="slick-prev slick-arrow" aria-label="Previous" type="button"><svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" width="24" height="24" viewBox="0 0 24 24"><path fill="#{$gray-800}" d="M14.41,18.16L8.75,12.5L14.41,6.84L15.11,7.55L10.16,12.5L15.11,17.45L14.41,18.16Z"></path></svg></button>',
  //   nextArrow: '<button class="slick-next slick-arrow" aria-label="Previous" type="button"><svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" width="24" height="24" viewBox="0 0 24 24"><path fill="#{$gray-800}" d="M8.59,18.16L14.25,12.5L8.59,6.84L7.89,7.55L12.84,12.5L7.89,17.45L8.59,18.16Z"></path></svg></button>',
  //   dots: false,
  //   // edgeFriction: 2,
  //   infinite: false,
  //   speed: 400,
  //   slidesToShow: 5.5,
  //   slidesToScroll: 5,
  //   variableWidth: true,
  //   touchThreshold: 10,
  //   swipeToSlide: true,
  //   responsive: [
  //     {
  //       breakpoint: 1750,
  //       settings: {
  //         slidesToShow: 3.5,
  //         slidesToScroll: 3.5,
  //         // infinite: true
  //         // dots: true
  //       }
  //     },
  //     {
  //       breakpoint: 1250,
  //       settings: {
  //         slidesToShow: 2.5,
  //         slidesToScroll: 2.5,
  //         // infinite: true
  //         // dots: true
  //       }
  //     },
  //     {
  //       breakpoint: 1024,
  //       settings: {
  //         slidesToShow: 1.5,
  //         slidesToScroll: 1.5,
  //         // infinite: true
  //         // dots: true
  //       }
  //     },
  //     {
  //       breakpoint: 768,
  //       settings: {
  //         slidesToShow: 2.5,
  //         slidesToScroll: 2.5
  //       }
  //     },
  //     {
  //       breakpoint: 720,
  //       settings: {
  //         slidesToShow: 1.5,
  //         slidesToScroll: 1.5
  //       }
  //     }
  //     // You can unslick at a given breakpoint now by adding:
  //     // settings: "unslick"
  //     // instead of a settings object
  //   ]
  // });

  // Initialize Tooltips
  $('[data-toggle="tooltip"]').tooltip({
    // Delay tooltip from appearing until after an item has been hovered on for a moment
    delay: {
      "show": 750,
      "hide": 250
    }
  });

});
