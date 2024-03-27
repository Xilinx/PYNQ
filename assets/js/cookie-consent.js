// Copyright (C) 2023 Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT

document.addEventListener('DOMContentLoaded', function () {
    // Check if the user has already given consent
	if (localStorage.getItem('cookieConsent')) {
        // Initialize Google Analytics if consent is already given
        initializeGoogleAnalytics();
    }else{
		// Show the cookie consent banner
		showCookieConsent();
	}
});

function showCookieConsent() {
    var cookieConsent = document.getElementById('cookie-consent');

    // Display the cookie consent banner
    cookieConsent.style.display = 'block';

    // Add event listener to the "Got it!" link
    document.getElementById('cookie-accept').addEventListener('click', function () {
        // Set a localStorage flag to remember user's consent
        localStorage.setItem('cookieConsent', true);

        // Hide the cookie consent banner
        cookieConsent.style.display = 'none';

        // Add Google Analytics tracking code
        initializeGoogleAnalytics();
    });

    // Add event listener to the "Reject" link
    document.getElementById('cookie-reject').addEventListener('click', function () {
        // Set a localStorage flag to remember user's rejection
        localStorage.setItem('cookieRejected', true);

        // Hide the cookie consent banner
        cookieConsent.style.display = 'none';
    });
}

function initializeGoogleAnalytics() {
	//console.log("Add Google Analytics tracking code");
    // Add Google Analytics tracking code
    (function (i, s, o, g, r, a, m) {
        i['GoogleAnalyticsObject'] = r;
        (i[r] =
            i[r] ||
            function () {
                (i[r].q = i[r].q || []).push(arguments);
            }),
            (i[r].l = 1 * new Date());
        (a = s.createElement(o)), (m = s.getElementsByTagName(o)[0]);
        a.async = 1;
        a.src = g;
        m.parentNode.insertBefore(a, m);
    })(
        window,
        document,
        'script',
        'https://www.googletagmanager.com/gtag/js?id=G-MV1L2SX33L',
        'gtag'
    );

    gtag('js', new Date());
    gtag('config', 'G-MV1L2SX33L');
}
