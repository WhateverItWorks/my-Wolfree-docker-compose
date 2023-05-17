# syntax=docker/dockerfile:1
# SPDX-License-Identifier: AGPL-3.0-or-later

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# Docker Docs: How to build, share, and run applications | Docker Documentation
# https://docs.docker.com/
FROM fedora

# Using the DNF software package manager :: Fedora Docs
# https://docs.fedoraproject.org/en-US/quick-docs/dnf/
RUN dnf --assumeyes upgrade


# Tor Project | How to install Tor
# https://community.torproject.org/onion-services/setup/install/
COPY <<"EOT" /etc/yum.repos.d/tor.repo
[tor]
name=Tor for Fedora $releasever - $basearch
baseurl=https://rpm.torproject.org/fedora/$releasever/$basearch
enabled=1
gpgcheck=1
gpgkey=https://rpm.torproject.org/fedora/public_gpg.key
cost=100
EOT


RUN dnf --assumeyes install wget2
RUN dnf --assumeyes install nginx
RUN dnf --assumeyes install tor


# Tor Project | Set up Your Onion Service
# https://community.torproject.org/onion-services/setup/
COPY <<"EOT" /etc/tor/torrc
HiddenServiceDir /var/lib/tor/my_website/
HiddenServicePort 80 127.0.0.1:80
EOT


RUN <<"EOT"
    wget2 --page-requisites --convert-links https://www.wolframalpha.com/input/index.html
    :
EOT


RUN <<"EOT"
    sed '
        s/.*js...static.chunks........../https:\/\/www.wolframalpha.com\/_next\/static\/chunks\// ;
        s/".......js.....miniCssF.*/.js\n/ ;
        s/:"/./g ;
        s/",/.js\nhttps:\/\/www.wolframalpha.com\/_next\/static\/chunks\//g ;
    ' /www.wolframalpha.com/_next/static/chunks/webpack* |
    wget2 --page-requisites --convert-links --input-file -
    :
EOT


RUN <<"EOT"
    sed '
        s/.*return.static.css..../https:\/\/www.wolframalpha.com\/_next\/static\/css\// ;
        s/........css.......function.*/.css\n/ ;
        s/[0-9]*:"//g ;
        s/",/.css\nhttps:\/\/www.wolframalpha.com\/_next\/static\/css\//g ;
    ' /www.wolframalpha.com/_next/static/chunks/webpack* |
    wget2 --page-requisites --convert-links --input-file -
    :
EOT


# Deploying NGINX and NGINX Plus on Docker | NGINX Plus
# https://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-docker/#managing-content-and-configuration-files
RUN rm -r /usr/share/nginx/html/
RUN mv /www.wolframalpha.com/ /usr/share/nginx/html/

# Remove the Wolfram Alpha logo.
RUN true | tee /usr/share/nginx/html/_next/static/images/*


# Reduce the number of error messages output to the Web console.
COPY <<"EOT" /usr/share/nginx/html/users/me/account
EOT


COPY <<"EOT" /usr/share/nginx/html/n/v1/api/randomizer
EOT


# /input?i=California
COPY <<"EOT" /usr/share/nginx/html/n/v1/api/sourcer/index.html
EOT


# /input?i=California
COPY <<"EOT" /usr/share/nginx/html/n/v1/api/sourcer/dataSources
EOT


# <span>Upload</span>
COPY <<"EOT" /usr/share/nginx/html/n/v1/api/samplefiles/fileinput/examples
EOT


COPY <<"EOT" /usr/share/nginx/html/n/v1/api/autocomplete/index.html
EOT


RUN wget2 --directory-prefix=/usr/share/nginx/html/input/ https://raw.githubusercontent.com/cure53/DOMPurify/main/dist/purify.min.js
RUN wget2 --directory-prefix=/usr/share/nginx/html/input/ https://ajax.googleapis.com/ajax/libs/jquery/3.6.3/jquery.min.js
RUN wget2 --directory-prefix=/usr/share/nginx/html/       https://unpkg.com/chota@0.8.1/dist/chota.min.css


RUN <<"EOT"
    echo '
        <!--
            https://developer.mozilla.org/en-US/docs/Web/HTML/Element/meta/name
            Do not send a HTTP Referer header.
            Resolve the error message: "Blocked referer"
        -->
        <meta name="referrer" content="no-referrer">
        <!-- Prevent XSS attacks with DOMPurify.sanitize(). -->
        <script src="/input/purify.min.js"> </script>
        <!-- Resolve CORS errors with jQuery.ajax() JSONP. -->
        <script src="/input/jquery.min.js"> </script>
        <!-- Create the wolfree object. -->
        <script src="/input/wolfree.js">    </script>
    ' >> /usr/share/nginx/html/input/index.html
EOT


# Inject some JavaScript code snippets that listen to the messages sent to Wolfram API.
#
# Request URL:
#
# wss://www.wolframalpha.com/n/v1/api/fetcher/results
#
# Messages:
#
# {
#   "type": "newQuery",
#   "locationId": "/input/?i=y%27%3Dy",
#   "language": "en",
#   "displayDebuggingInfo": false,
#   "yellowIsError": false,
#   "requestSidebarAd": false,
#   "category": "results",
#   "input": "y'=y",
#   "i2d": false,
#   "assumption": [],
#   "apiParams": {},
#   "file": null
# }
#
# {
#   "type": "newQuery",
#   "locationId": "/input/?i2d=true&i=y%27%3Dy",
#   "language": "en",
#   "displayDebuggingInfo": false,
#   "yellowIsError": false,
#   "requestSidebarAd": false,
#   "category": "results",
#   "input": "W3sidCI6MCwidiI6InknPXkifV0=",
#   "i2d": true,
#   "assumption": [],
#   "apiParams": {},
#   "file": null
# }


# What is Minifying? - How Next.js Works | Learn Next.js
# https://nextjs.org/learn/foundations/how-nextjs-works/minifying
# Wolfram uses the Next.js framework.
# The Next.js framework minifies and changes the variable names occasionally.
# If something goes wrong, check if the variable names near generateEncodedJSONFromValue have changed.
RUN <<"EOT"
    sed -i '
        s/try{m.i2d?m.value=pd(JSON.stringify(T.utils2D.generateEncodedJSONFromValue({value:m.value}))):m.value=T.utils2D.unescapeForUrl(m.value)}catch(v){}/ \
        m.value = new URLSearchParams(location.search).get`i` || `mathematics`; \
        m.i2d = new URLSearchParams(location.search).get`i2d` == `true`; \
        & \
        wolfree.i2d = m.i2d; \
        wolfree.input = m.value; \
        setTimeout(wolfree.main); \
        /
    ' /usr/share/nginx/html/_next/static/chunks/*.js
EOT
# before:
#
#     try {
#         m.i2d ? m.value = pd(JSON.stringify(T.utils2D.generateEncodedJSONFromValue({
#             value: m.value
#         }))) : m.value = T.utils2D.unescapeForUrl(m.value)
#     } catch (v) {}
#
# after:
#
#     m.value = new URLSearchParams(location.search).get`i` || `mathematics`;
#     m.i2d = new URLSearchParams(location.search).get`i2d` == `true`;
#     try {
#         m.i2d ? m.value = pd(JSON.stringify(T.utils2D.generateEncodedJSONFromValue({
#             value: m.value
#         }))) : m.value = T.utils2D.unescapeForUrl(m.value)
#     } catch (v) {}
#     wolfree.i2d = m.i2d;
#     wolfree.input = m.value;
#     setTimeout(wolfree.main);


RUN <<"EOT"
    sed -i '
        s/webSocket=new WebSocket/ \
        webSocket = new WebSocket(`wss:\/\/www.wolframalpha.com\/n\/v1\/api\/fetcher\/results`), \
        /
    ' /usr/share/nginx/html/_next/static/chunks/pages/*.js
EOT
# before:
#
#     t.webSocket = new WebSocket(t.url),
#
# after:
#
#     t.webSocket = new WebSocket(`wss://www.wolframalpha.com/n/v1/api/fetcher/results`),
#     (t.url),


COPY <<"EOT" /usr/share/nginx/html/input/wolfree.js
// SPDX-License-Identifier: AGPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
'use strict'
const wolfree = {
    main: async () => {
        // To generate a new AppID:
        //  1. Open Tor Browser and go to: https://products.wolframalpha.com/api/
        //  2. Click the orangish "Get API Access" button. You will go to: https://account.wolfram.com/login/oauth2/sign-in
        //  3. Click the reddish "Create one" hyperlink to create a new Wolfram ID. You will go to: https://account.wolfram.com/login/create
        //  4. Fill out the form using random alphanumeric characters.
        //  5. Click the reddish "Create Wolfram ID" button. You will go to: https://developer.wolframalpha.com/portal/myapps/index.html
        //  6. Click the orangish "Sign up to get your first AppID" button.
        //  7. Fill out the form using random alphanumeric characters.
        //  8. Click the orangish "Sign up" button.
        //  9. Click the orangish "Get an AppID" button.
        // 10. Fill out the form using random alphanumeric characters.
        // 11. Click the orangish "Get AppID" button.
        const appIDArray = [
            'H9V325-HTALUWHKGK',
            'AKJTJT-LR5LL8WTG6',
            'LKY83U-XW6ATU9URU',
        ]
        // f8RCUrgvdPqq return
        // hide the results of previous calculations
        setTimeout(
            () => {
                document.querySelectorAll`div[data-wolfree-pods]`.forEach(
                    element => element.remove()
                )
            }
        )
        // show the skeleton placeholder components
        document.querySelector`
            div [class="_3Cg6"],
            div [class="_2UIf"]
        `.insertAdjacentHTML(
            'afterend',
            `
                <div
                    class=_3VFW
                    data-wolfree-placeholder
                >
                    <div class=_2ThP>
                        <div class=_8sqm>
                            <div class=_1J6z> <div class="_1Ixl _3vsh _32ge"> </div> </div>
                            <div class=_1J6z> <div class="_3_kv _3vsh _32ge"> </div> </div>
                            <div class=_1J6z> <div class="_20Sm _3vsh _32ge"> </div> </div>
                        </div>
                    </div>
                </div>
            `
        )
        const response = await jQuery.ajax(
            {
                // https://products.wolframalpha.com/api/documentation
                // https://learn.jquery.com/ajax/working-with-jsonp/
                // https://stackoverflow.com/questions/30008144/jquery-ajax-data-object-with-multiple-values-for-the-same-key
                // https://stackoverflow.com/questions/11704267/in-javascript-how-to-conditionally-add-a-member-to-an-object
                url: 'https://api.wolframalpha.com/v2/query',
                dataType: 'jsonp',
                traditional: true,
                data: {
                    output: 'json',
                    reinterpret: true,
                    podtimeout: 30,
                    scantimeout: 30,
                    parsetimeout: 30,
                    totaltimeout: 30,
                    formattimeout: 30,
                    appid: appIDArray[
                        // https://stackoverflow.com/questions/41437492/how-to-use-window-crypto-getrandomvalues-to-get-random-values-in-a-specific-rang
                        crypto.getRandomValues(new Uint32Array(1)) % appIDArray.length
                    ],
                    podstate: [
                        'Step-by-step solution',
                        'Step-by-step',
                        'Show all steps',
                        wolfree.podstate,
                    ],
                    ... wolfree.i2d && {i2d: wolfree.i2d},
                    input: wolfree.input,
                },
            }
        )
        // hide the skeleton placeholder components
        setTimeout(
            () => {
                document.querySelectorAll`div[data-wolfree-placeholder]`.forEach(
                    element => element.remove()
                )
            }
        )
        document.querySelector`
            div [class="_3Cg6"],
            div [class="_2UIf"]
        `.insertAdjacentHTML(
            'afterend',
            // https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/Safely_inserting_external_content_into_a_page#working_with_html_content
            // https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html#html-sanitization
            DOMPurify.sanitize(
                // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Template_literals#nesting_templates
                `
                    <div
                        class=_3BQG
                        data-wolfree-pods
                        style="
                            padding-left:  0;
                            padding-right: 0;
                        "
                    >
                        <div class=_2ThP>
                            <div class=_pA1m>
                                <section class=_1vuO>
                                    ${
                                        response.queryresult.pods?.map(
                                            pod => `
                                                <section class=_gtUC>
                                                    ${
                                                        `
                                                            <header class=_2Qm3>
                                                                <h2 class=_3OwK>
                                                                    ${pod.title}
                                                                </h2>
                                                                ${
                                                                    pod.states?.map(
                                                                        state => state.states ? `
                                                                            <select
                                                                                style="
                                                                                    background: white;
                                                                                    border-radius: 4px;
                                                                                    color: orangered;
                                                                                    border: thin solid darkorange
                                                                                "
                                                                            >
                                                                                <option>${state.value}</option>
                                                                                ${
                                                                                    state.states.map(
                                                                                        state => `
                                                                                            <option>${state.name}</option>
                                                                                        `
                                                                                    ).join``
                                                                                }
                                                                            </select>
                                                                        ` : ''
                                                                    ).join('') || ''
                                                                }
                                                            </header>
                                                            <div class=_1brB> </div>
                                                            ${
                                                                pod.subpods.map(
                                                                    subpod => `
                                                                        <div class=_1brB>
                                                                            <div class=_3fR4>
                                                                                <img
                                                                                    class=_3c8e
                                                                                    style=width:auto
                                                                                    src=${subpod.img.src}
                                                                                >
                                                                            </div>
                                                                        </div>
                                                                        <div
                                                                            class=_1brB
                                                                            style="
                                                                                font-family: monospace;
                                                                                overflow: auto;
                                                                            "
                                                                        >
                                                                            <div class=_3fR4>
                                                                                <details>
                                                                                    <summary style=direction:rtl>
                                                                                    </summary>
                                                                                    <div
                                                                                        contenteditable
                                                                                        style=padding:1rem
                                                                                    >
                                                                                        <pre>${subpod.plaintext}</pre>
                                                                                    </div>
                                                                                    <br>
                                                                                </details>
                                                                            </div>
                                                                        </div>
                                                                    `
                                                                ).join``
                                                            }
                                                        `
                                                    }
                                                </section>
                                            `
                                        ).join('') || ''
                                    }
                                    <section class=_gtUC>
                                        <header class=_2Qm3>
                                            <h2 class=_3OwK>
                                                Wolfree diagnostics
                                            </h2>
                                        </header>
                                        <div class=_1brB> </div>
                                        <div
                                            class=_1brB
                                            style="
                                                font-family: monospace;
                                                overflow: auto;
                                            "
                                        >
                                            <div class=_3fR4>
                                                <details>
                                                    <br>
                                                    <div
                                                        contenteditable
                                                        style="padding: 1rem; line-height: 2;"
                                                    >
                                                        If something goes wrong, <br>
                                                        you can report the error <br>
                                                        to the Wolfree community <br>
                                                        on the Fediverse.        <br>
                                                                                 <br>
                                                        When using the Fediverse <br>
                                                        to report an error, send <br>
                                                        the following diagnostic <br>
                                                        info to help investigate <br>
                                                        the causes of the error. <br>
                                                                                 <br>
                                                        <pre>${
                                                            JSON.stringify(
                                                                {
                                                                    wolfree,
                                                                    document,
                                                                    userAgent: navigator?.userAgent,
                                                                    Date: Date(),
                                                                    DateTimeFormat: Intl?.DateTimeFormat()?.resolvedOptions(),
                                                                    response,
                                                                },
                                                                null,
                                                                4
                                                            )
                                                        }</pre>
                                                    </div>
                                                    <br>
                                                </details>
                                            </div>
                                        </div>
                                        <div class=_1brB> </div>
                                    </section>
                                </section>
                            </div>
                        </div>
                    </div>
                `,
                // https://github.com/cure53/DOMPurify#can-i-configure-dompurify
                {ADD_ATTR: ['contenteditable']}
            )
        )
        setTimeout( // Use the drop down menu for different problem-solving strategies
            () => {
                // https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/change_event
                document.querySelectorAll`select`.forEach(
                    element => element.addEventListener(
                        'change',
                        event => {
                            wolfree.podstate = event.target.value
                            setTimeout(wolfree.main)
                            window.scroll(0,0)
                        }
                    )
                )
            }
        )
    },
    customize: () => {
        [
            {selector: 'header',                                                             includes: 'UPGRADE TO PRO'},
            {selector: 'a[href="https://www.wolframalpha.com/pro/pricing/students"]',        includes: ''},
            {selector: 'a[href="https://www.wolframalpha.com/"]',                            includes: ''},
            {selector: 'div[role="tooltip"]',                                                includes: 'to directly enter textbook math notation'},
            {selector: 'a[href="https://www.wolframalpha.com/examples"]',                    includes: ''},
            {selector: 'main section section ul li button',                                  includes: 'Step-by-step solution'},
            {selector: 'img[alt="OUTPUT_ZOOM_HEADER"]',                                      includes: ''},
            {selector: 'img[alt="DATA_DOWNLOAD_HEADER"]',                                    includes: ''},
            {selector: 'img[alt="CUSTOMIZE_HEADER"]',                                        includes: ''},
            {selector: 'img[alt="PLAIN_TEXT_HEADER"]',                                       includes: ''},
            {selector: 'img[alt="SOURCES"]',                                                 includes: ''}, // /input/?i=California
            {selector: 'img[alt="Zoom in to see an enlarged view of any input."]',           includes: ''},
            {selector: 'img[alt="Tables & Spreadsheets icon"]',                              includes: ''},
            {selector: 'img[alt="Tables & Spreadsheets color icon"]',                        includes: ''},
            {selector: 'img[alt="Math Typesetting icon"]',                                   includes: ''},
            {selector: 'img[alt="Math Typesetting color icon"]',                             includes: ''},
            {selector: 'img[alt="Raster Graphics icon"]',                                    includes: ''},
            {selector: 'img[alt="Raster Graphics color icon"]',                              includes: ''},
            {selector: 'img[alt="Vector Graphics icon"]',                                    includes: ''},
            {selector: 'img[alt="Vector Graphics color icon"]',                              includes: ''},
            {selector: 'img[alt="Web Format icon"]',                                         includes: ''},
            {selector: 'img[alt="Web Format color icon"]',                                   includes: ''},
            {selector: 'img[alt="Wolfram Formats icon"]',                                    includes: ''},
            {selector: 'img[alt="Wolfram Formats color icon"',                               includes: ''},
            {selector: 'img[alt="Choose Color Scheme:"]',                                    includes: ''},
            {selector: 'a[href="/pro/pricing/"]',                                            includes: ''},
            {selector: 'a[href="https://www.wolframalpha.com/pro/"]',                        includes: ''},
            {selector: 'main span',                                                          includes: 'Already have Pro?'},
            {selector: 'main button[type="button"]',                                         includes: 'Sign in'},
            {selector: 'main span',                                                          includes: 'Download your full results as a single interactive or static document for offline use.'},
            {selector: 'main section',                                                       includes: 'Try again with Pro computation time'}, // Derivative[21][y][x] == y[x]
            {selector: 'a[href="/pro-premium-expert-support"]',                              includes: ''},
            {selector: 'a[href="/feedback"]',                                                includes: ''},
            {selector: 'footer',                                                             includes: 'Pro'},
            // <span>Upload</span>
            {selector: 'main h2 span',                                                       includes: '(PRO)'},
            {selector: 'main span',                                                          includes: 'Enter an image as an input to Wolfram|Alpha for analysis or processing.'},
            {selector: 'main span',                                                          includes: 'Feed numeric and tabular data into Wolfram|Alpha for analysis'},
            {selector: 'main span',                                                          includes: 'Run analyses and computations on 60+ types of data and other files.'},
            {selector: 'main span',                                                          includes: 'Try these sample images and see what Wolfram|Alpha Pro can do.'},
            {selector: 'main span',                                                          includes: 'Try this sample data and see what Wolfram|Alpha Pro can do'},
            {selector: 'main button[type="button"]',                                         includes: 'Sample Images'},
            {selector: 'main button[type="button"]',                                         includes: 'Sample Data'},
            {selector: 'main button[type="button"]',                                         includes: 'Supported formats and sample files'},
            {selector: 'a[href="https://www.wolframalpha.com/input/pro/uploadexamples/"]',   includes: ''},
            {selector: 'a[href="https://www.wolframalpha.com/termsofuse/"]',                 includes: ''},
            {selector: 'a[href="https://www.wolfram.com/legal/privacy/wolfram/index.html"]', includes: ''},
            {selector: 'main button[type="button"]',                                         includes: 'Upload a file'},
            // <span>Enlarge</span>
            {selector: 'main span',                                                          includes: 'Wolfram|Alpha Output Zoom'},
            {selector: 'main span',                                                          includes: 'Zoom in to see an enlarged view of any input.'},
            // <span>Data</span>
            {selector: 'main span',                                                          includes: 'Not for commercial distribution.'},
            {selector: 'main span',                                                          includes: 'Download raw data generated by Wolfram|Alpha for your use.'},
            {selector: 'a[href="https://www.wolframalpha.com/input/pro/downloadexamples/"]', includes: ''},
            {selector: 'a[href="https://www.wolframalpha.com/termsofuse"]',                  includes: ''},
            // <span>Customize</span>
            {selector: 'main span',                                                          includes: 'Save your customized Wolfram|Alpha results.'},
        ].forEach(
            data => Array.from(
                document.querySelectorAll(data.selector)
            ).filter(
                element => element.innerHTML.includes(data.includes)
            ).forEach(
                element => element.style.display = 'none'
            )
        )
        setTimeout( // insert the wolfree navbar
            () => document.querySelector`
                [data-wolfree-navbar]
            ` || document.querySelector`
                body
            `.insertAdjacentHTML(
                'afterbegin',
                `
                    <style>
                        [data-wolfree-navbar] {
                            line-height: 3;
                            flex-flow: row wrap;
                            max-width: 780px;
                            display: flex;
                            margin: 1rem auto;
                        }
                        [data-wolfree-navbar] > div {
                            text-align: center;
                            display: flex;
                            flex: auto;
                        }
                        [data-wolfree-navbar] > div > a {
                            font-family: sans-serif;
                            text-decoration: none;
                            margin: auto 0.3rem;
                            flex: auto;
                        }
                    </style>
                    <nav data-wolfree-navbar>
                        <div>
                            <a href="/">Wolfree</a>
                            <a href="/input/">Input</a>
                            <a href="/mirror/">Mirror</a>
                        </div>
                        <div>
                            <a href="/#source">Source</a>
                            <a href="/#fediverse">Fediverse</a>
                            <a href="/dmca/">DMCA</a>
                        </div>
                    </nav>
                `
            )
        )
        document.title = document.title.replace(
            '- Wolfram|Alpha',
            '- Free Wolfram Alpha Step-by-step Solution - Wolfree'
        )
    },
}
addEventListener(
    // https://developer.mozilla.org/en-US/docs/Web/API/Window/load_event
    'load',
    async () => {
        while (document.activeElement != document.querySelector`input`) {
            // focus on the orangish input box
            document.querySelector`input`.focus()
            // https://stackoverflow.com/questions/951021/what-is-the-javascript-version-of-sleep
            await new Promise(resolve => setTimeout(resolve, 1000))
        }
    }
)
addEventListener(
    // https://developer.mozilla.org/en-US/docs/Web/API/Element/click_event
    'click',
    () => setTimeout(wolfree.customize)
)
setInterval(wolfree.customize, 1000)
EOT


COPY <<"EOT" /usr/share/nginx/html/instances.json
{
    "wolfree": {
        "clearnet": [
            "https://wolfree.chickenkiller.com/",
            "https://wolfree.crabdance.com/",
            "https://wolfree.gitlab.io/",
            "https://wolfree.glitch.me/",
            "https://wolfree.ignorelist.com/",
            "https://wolfree.jumpingcrab.com/",
            "https://wolfree.mooo.com/",
            "https://wolfree.my.to/",
            "https://wolfree.netlify.app/",
            "https://wolfree.on.fleek.co/",
            "https://wolfree.onrender.com/",
            "https://wolfree.pages.dev/",
            "https://wolfree.privatedns.org/",
            "https://wolfree.strangled.net/",
            "https://wolfree.twilightparadox.com/",
            "https://wolfree.uk.to/",
            "https://wolfree.us.to/",
            "https://wolfreealpha.chickenkiller.com/",
            "https://wolfreealpha.crabdance.com/",
            "https://wolfreealpha.gitlab.io/",
            "https://wolfreealpha.glitch.me/",
            "https://wolfreealpha.ignorelist.com/",
            "https://wolfreealpha.jumpingcrab.com/",
            "https://wolfreealpha.mooo.com/",
            "https://wolfreealpha.my.to/",
            "https://wolfreealpha.netlify.app/",
            "https://wolfreealpha.on.fleek.co/",
            "https://wolfreealpha.onrender.com/",
            "https://wolfreealpha.pages.dev/",
            "https://wolfreealpha.privatedns.org/",
            "https://wolfreealpha.strangled.net/",
            "https://wolfreealpha.twilightparadox.com/",
            "https://wolfreealpha.uk.to/",
            "https://wolfreealpha.us.to/"
        ],
        "tor": [],
        "i2p": [],
        "loki": []
    }
}
EOT


COPY <<"EOT" /usr/share/nginx/html/mirror/index.html
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <meta
            name="description"
            content="Bookmark the following mirror sites so you can try other mirrors when the Internet service providers have broken the Internet connection to this site."
        >
        <title>Mirror - Wolfree</title>
        <link rel="stylesheet" href="/chota.min.css">
        <style>
            :root {
                --color-primary: blue;
            }
            html {
                margin: 1rem;
            }
            body {
                line-height: 4rem;
                max-width: 30em;
                margin: auto;
                color: black;
                font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, "Noto Sans", sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol", "Noto Color Emoji";
            }
            section {
                margin: 9rem auto;
            }
            a {
                text-decoration: none;
                word-wrap: break-word;
            }
            .button, #input {
                border-radius: 3rem;
                padding: 1rem 2rem;
                margin: 1.3rem auto;
            }
            ::placeholder {
                color: black;
            }
        </style>
        <style>
            [data-wolfree-navbar] {
                line-height: 3;
                flex-flow: row wrap;
                max-width: 780px;
                display: flex;
                margin: 1rem auto;
            }
            [data-wolfree-navbar] > div {
                text-align: center;
                display: flex;
                flex: auto;
            }
            [data-wolfree-navbar] > div > a {
                font-family: sans-serif;
                text-decoration: none;
                margin: auto 0.3rem;
                flex: auto;
            }
        </style>
    </head>
    <body>
        <nav data-wolfree-navbar>
            <div>
                <a href="/">Wolfree</a>
                <a href="/input/">Input</a>
                <a href="/mirror/">Mirror</a>
            </div>
            <div>
                <a href="/#source">Source</a>
                <a href="/#fediverse">Fediverse</a>
                <a href="/dmca/">DMCA</a>
            </div>
        </nav>
        <section>
            <h1 id=mirror>Mirror</h1>
            <p>
                Bookmark the following mirror sites so you can try other mirrors when the Internet service providers have broken the Internet connection to this site.
                Machine-readable data: <a href="/instances.json">instances.json</a>
            </p>
            <ol>
                <li><a>https://wolfree.chickenkiller.com/</a></li>
                <li><a>https://wolfree.crabdance.com/</a></li>
                <li><a>https://wolfree.gitlab.io/</a></li>
                <li><a>https://wolfree.glitch.me/</a></li>
                <li><a>https://wolfree.ignorelist.com/</a></li>
                <li><a>https://wolfree.jumpingcrab.com/</a></li>
                <li><a>https://wolfree.mooo.com/</a></li>
                <li><a>https://wolfree.my.to/</a></li>
                <li><a>https://wolfree.netlify.app/</a></li>
                <li><a>https://wolfree.on.fleek.co/</a></li>
                <li><a>https://wolfree.onrender.com/</a></li>
                <li><a>https://wolfree.pages.dev/</a></li>
                <li><a>https://wolfree.privatedns.org/</a></li>
                <li><a>https://wolfree.strangled.net/</a></li>
                <li><a>https://wolfree.twilightparadox.com/</a></li>
                <li><a>https://wolfree.uk.to/</a></li>
                <li><a>https://wolfree.us.to/</a></li>
                <li><a>https://wolfreealpha.chickenkiller.com/</a></li>
                <li><a>https://wolfreealpha.crabdance.com/</a></li>
                <li><a>https://wolfreealpha.gitlab.io/</a></li>
                <li><a>https://wolfreealpha.glitch.me/</a></li>
                <li><a>https://wolfreealpha.ignorelist.com/</a></li>
                <li><a>https://wolfreealpha.jumpingcrab.com/</a></li>
                <li><a>https://wolfreealpha.mooo.com/</a></li>
                <li><a>https://wolfreealpha.my.to/</a></li>
                <li><a>https://wolfreealpha.netlify.app/</a></li>
                <li><a>https://wolfreealpha.on.fleek.co/</a></li>
                <li><a>https://wolfreealpha.onrender.com/</a></li>
                <li><a>https://wolfreealpha.pages.dev/</a></li>
                <li><a>https://wolfreealpha.privatedns.org/</a></li>
                <li><a>https://wolfreealpha.strangled.net/</a></li>
                <li><a>https://wolfreealpha.twilightparadox.com/</a></li>
                <li><a>https://wolfreealpha.uk.to/</a></li>
                <li><a>https://wolfreealpha.us.to/</a></li>
            </ol>
            <p>
            </p>
        </section>
        <section>
            <h2>Acknowledgment</h2>
            <p>
                See the <a href="/acknowledgment/">acknowledgment page</a> for details.
            </p>
        </section>
        <script>
            setTimeout(
                () => document.querySelectorAll`
                    a:not([href])
                `.forEach(
                    element => element.href = element.innerText
                )
            )
        </script>
        <script>
            setTimeout(
                () => {
                    document.querySelectorAll`
                        h1,h2
                    `.forEach(
                        element => element.id = element.innerText.toLowerCase().replaceAll(' ', '-')
                    )
                    setTimeout(
                        () => document.getElementById(location.hash.slice(1))?.scrollIntoView()
                    )
                }
            )
        </script>
    </body>
</html>
EOT


COPY <<"EOT" /usr/share/nginx/html/dmca/index.html
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <meta
            name="description"
            content="The math output from scientific calculators on the Wolfree mirror sites may be objectionable."
        >
        <title>DMCA - Wolfree</title>
        <link rel="stylesheet" href="/chota.min.css">
        <style>
            :root {
                --color-primary: blue;
            }
            html {
                margin: 1rem;
            }
            body {
                line-height: 4rem;
                max-width: 30em;
                margin: auto;
                color: black;
                font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, "Noto Sans", sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol", "Noto Color Emoji";
            }
            section {
                margin: 9rem auto;
            }
            a {
                text-decoration: none;
                word-wrap: break-word;
            }
            .button, #input {
                border-radius: 3rem;
                padding: 1rem 2rem;
                margin: 1.3rem auto;
            }
            ::placeholder {
                color: black;
            }
        </style>
        <style>
            [data-wolfree-navbar] {
                line-height: 3;
                flex-flow: row wrap;
                max-width: 780px;
                display: flex;
                margin: 1rem auto;
            }
            [data-wolfree-navbar] > div {
                text-align: center;
                display: flex;
                flex: auto;
            }
            [data-wolfree-navbar] > div > a {
                font-family: sans-serif;
                text-decoration: none;
                margin: auto 0.3rem;
                flex: auto;
            }
        </style>
    </head>
    <body>
        <nav data-wolfree-navbar>
            <div>
                <a href="/">Wolfree</a>
                <a href="/input/">Input</a>
                <a href="/mirror/">Mirror</a>
            </div>
            <div>
                <a href="/#source">Source</a>
                <a href="/#fediverse">Fediverse</a>
                <a href="/dmca/">DMCA</a>
            </div>
        </nav>
        <section>
            <h1>DMCA</h1>
            <p>
                Copyright owners may sue infringers, which can be expensive and time-consuming.
                The DMCA
                "<a href="https://en.wikipedia.org/wiki/Notice_and_take_down">notice and takedown</a>"
                process is much cheaper and takes less time.
            </p>
        </section>
        <section>
            <h2>DMCA takedown notice</h2>
            <p>
                Here are some DMCA takedown notices from Wolfram Alpha LLC.
            </p>
            <ul>
                <li><a href="https://github.com/github/dmca/blob/master/2021/08/2021-08-11-wolfram.md">2021-08-11-wolfram.md</a></li>
                <li><a href="https://github.com/github/dmca/blob/master/2021/08/2021-08-16-wolfram.md">2021-08-16-wolfram.md</a></li>
                <li><a href="https://github.com/github/dmca/blob/master/2022/09/2022-09-22-wolfram.md">2022-09-22-wolfram.md</a></li>
            </ul>
            <p>
                The math output from scientific calculators on the Wolfree mirror sites may be objectionable.
                If you believe someone is using your copyrighted content unauthorizedly on Microsoft GitHub,
                fill out the form hyperlinked below to submit a DMCA takedown notice to request that the content be changed or removed.
            </p>
            <ul>
                <li><a>https://support.github.com/contact/dmca-takedown</a></li>
            </ul>
            <p>
                As with all legal matters, it is always best to consult a professional about your questions or situation.
                The Wolfree community strongly encourages you to do so before taking action that might impact your rights.
                All content on this site is not legal advice.
            </p>
        </section>
        <script>
            setTimeout(
                () => document.querySelectorAll`
                    a:not([href])
                `.forEach(
                    element => element.href = element.innerText
                )
            )
        </script>
        <section>
            <h2>Acknowledgment</h2>
            <p>
                See the <a href="/acknowledgment/">acknowledgment page</a> for details.
            </p>
        </section>
        <script>
            setTimeout(
                () => {
                    document.querySelectorAll`
                        h1,h2
                    `.forEach(
                        element => element.id = element.innerText.toLowerCase().replaceAll(' ', '-')
                    )
                    setTimeout(
                        () => document.getElementById(location.hash.slice(1))?.scrollIntoView()
                    )
                }
            )
        </script>
    </body>
</html>
EOT


COPY <<"EOT" /usr/share/nginx/html/acknowledgment/index.html
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <meta
            name="description"
            content="Web services that indirectly benefit the Wolfree community on the Fediverse"
        >
        <title>Acknowledgment - Wolfree</title>
        <link rel="stylesheet" href="/chota.min.css">
        <style>
            :root {
                --color-primary: blue;
            }
            html {
                margin: 1rem;
            }
            body {
                line-height: 4rem;
                max-width: 30em;
                margin: auto;
                color: black;
                font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, "Noto Sans", sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol", "Noto Color Emoji";
            }
            section {
                margin: 9rem auto;
            }
            a {
                text-decoration: none;
                word-wrap: break-word;
            }
            .button, #input {
                border-radius: 3rem;
                padding: 1rem 2rem;
                margin: 1.3rem auto;
            }
            ::placeholder {
                color: black;
            }
        </style>
        <style>
            [data-wolfree-navbar] {
                line-height: 3;
                flex-flow: row wrap;
                max-width: 780px;
                display: flex;
                margin: 1rem auto;
            }
            [data-wolfree-navbar] > div {
                text-align: center;
                display: flex;
                flex: auto;
            }
            [data-wolfree-navbar] > div > a {
                font-family: sans-serif;
                text-decoration: none;
                margin: auto 0.3rem;
                flex: auto;
            }
        </style>
    </head>
    <body>
        <nav data-wolfree-navbar>
            <div>
                <a href="/">Wolfree</a>
                <a href="/input/">Input</a>
                <a href="/mirror/">Mirror</a>
            </div>
            <div>
                <a href="/#source">Source</a>
                <a href="/#fediverse">Fediverse</a>
                <a href="/dmca/">DMCA</a>
            </div>
        </nav>
        <section>
            <h1>Acknowledgment</h1>
            <p>
                The following communities are not directly involved in the Wolfree community but have contributed conceptual inspiration or criticism.
                They may create Web services that indirectly benefit the Wolfree community on the Fediverse.
            </p>
        </section>
        <section>
            <h2>The Fediverse</h2>
            <p>
                The
                <a href="https://en.wikipedia.org/wiki/Fediverse">Fediverse</a>
                is a federated social network consisting of independently hosted servers.
                There are autonomous servers for blogging, photo sharing, and video sharing,
                and they are all interconnected seamlessly.
                So you only need one account to follow anyone on any compatible social media platform.
            </p>
            <ul>
                <li><a>https://fediverse.info/</a> is a bespoke guide to the Fediverse.</li>
                <li><a>https://docs.joinmastodon.org/</a> is the Mastodon documentation.</li>
                <li><a>https://joinfediverse.wiki/</a> is an encyclopedia dedicated to the Fediverse.</li>
            </ul>
            <p>
                Thanks to the people on the Fediverse,
                the website operators of the Wolfree mirror sites and the programmers of the Wolfree Dockerfile can collaborate freely.
            </p>
            <ul>
                <li><a>http://demo.fedilist.com/</a> indexes new instances.</li>
                <li><a>https://fba.ryona.agency/scoreboard?blockers=100</a> indexes the top 100 defederating servers.</li>
                <li><a>https://fba.ryona.agency/scoreboard?blocked=100</a> indexes the top 100 defederated servers.</li>
            </ul>
        </section>
        <section>
            <h2>Gitea</h2>
            <p>
                <a href="https://en.wikipedia.org/wiki/Gitea">Gitea</a> is a community-managed code hosting solution.
                Thanks to the people on Gitea,
                the programmers of the Wolfree Dockerfile can distribute the source code on the Fediverse freely.
            </p>
            <ul>
                <li><a>https://gitea.io/</a> develops a self-hosted Git service.</li>
                <li><a>https://forgefed.org/</a> is a federation protocol between version control services.</li>
                <li><a>https://forgefriends.org/</a> is an online service to federate forges.</li>
                <li><a href="http://demo.fedilist.com/instance?q=&ip=&software=gitea&registrations=&onion=">http://demo.fedilist.com/</a> is a list of instances on the Fediverse with some information about the Fediverse in general.</li>
                <li><a>https://the-federation.info/platform/148</a> indexes a node list and statistics for the Fediverse</li>
            </ul>
        </section>
        <section>
            <h2>Copyleft</h2>
            <p>
                Copyleft says that anyone who redistributes the software, with or without changes, must pass along the freedom to copy and change it further.
            </p>
            <ul>
                <li><a>https://blueoakcouncil.org/primer</a> is a short, practical guide to open software licensing.</li>
                <li><a>https://www.gnu.org/licenses/copyleft.html.en</a> explains what copyleft is.</li>
                <li><a>https://www.gnu.org/philosophy/why-copyleft.html.en</a> illustrates the benefits of copyleft.</li>
                <li><a>https://lukesmith.xyz/articles/why-i-use-the-gpl-and-not-cuck-licenses/</a> elaborates on the advantages of copyleft.</li>
            </ul>
        </section>
        <section>
            <h2>Internet Archive</h2>
            <p>
                The <a href="https://en.wikipedia.org/wiki/Internet_Archive">Internet Archive</a> is a non-profit library that lends digital copies of books.
                Penguin Random House, HarperCollins, Hachette, and Wiley claim that the Internet Archive infringes copyright by lending digital books.
            </p>
            <ul>
                <li><a>https://www.eff.org/cases/hachette-v-internet-archive</a></li>
                <li><a>https://www.eff.org/press/releases/internet-archive-seeks-summary-judgment-federal-lawsuit-filed-publishing-companies</a></li>
                <li><a>https://www.eff.org/deeplinks/2023/01/fair-use-creep-feature-not-bug</a></li>
            </ul>
        </section>
        <section>
            <h2>Sci-Hub</h2>
            <p>
                <a href="https://en.wikipedia.org/wiki/Sci-Hub">Sci-Hub</a>
                is a shadow library website that provides free access to millions of research papers and books.
            </p>
            <ul>
                <li><a>https://sci-hub.se/</a></li>
                <li><a>https://sci-hub.st/</a></li>
                <li><a>https://sci-hub.ru/</a></li>
            </ul>
        </section>
        <section>
            <h2>Library Genesis</h2>
            <p>
                <a href="https://en.wikipedia.org/wiki/Library_Genesis">Library Genesis</a>
                (Libgen) is a shadow library website for scholarly journal articles, academic and general-interest books, audiobooks, and magazines.
            </p>
            <ul>
                <li><a>http://libgen.fun/</a></li>
                <li><a>http://library.lol/</a></li>
                <li><a>http://libgen.rocks/</a></li>
            </ul>
        </section>
        <section>
            <h2>Censorship circumvention</h2>
            <p>
                Learn how to circumvent censorship on the Internet safely.
            </p>
            <ul>
                <li><a>https://privacyguides.org/</a> promotes data security and privacy.</li>
                <li><a>https://torproject.org/</a> is a Web browser capable of accessing the Tor network.</li>
                <li><a>https://tails.boum.org/</a> is a Linux distribution aimed at preserving privacy and anonymity.</li>
                <li><a>https://qubes-os.org/</a> is a Linux distribution that provides security through isolation.</li>
                <li><a>https://anonymousplanet.org/</a> details online anonymity.</li>
            </ul>
        </section>
        <section>
            <h2>The Internet Infrastructure</h2>
            <p>
                The big-I Internet is falling apart and becoming many little-i internets.
                The Internet can be much healthier and more vibrant if we eliminate the artificial restrictions imposed by third parties.
                How do we preserve the Internet for future generations?
            </p>
            <ul>
                <li><a>https://www.eff.org/deeplinks/2022/12/we-need-talk-about-infrastructure</a></li>
                <li><a>https://madattheinternet.com/2021/07/08/where-the-sidewalk-ends-the-death-of-the-internet/</a></li>
                <li><a>https://www.eff.org/deeplinks/2022/10/internet-not-facebook-why-infrastructure-providers-should-stay-out-content</a></li>
            </ul>
        </section>
        <script>
            setTimeout(
                () => document.querySelectorAll`
                    a:not([href])
                `.forEach(
                    element => element.href = element.innerText
                )
            )
        </script>
        <script>
            setTimeout(
                () => {
                    document.querySelectorAll`
                        h1,h2
                    `.forEach(
                        element => element.id = element.innerText.toLowerCase().replaceAll(' ', '-')
                    )
                    setTimeout(
                        () => document.getElementById(location.hash.slice(1))?.scrollIntoView()
                    )
                }
            )
        </script>
    </body>
</html>
EOT


# What Is a Landing Page? Landing Pages Explained | Unbounce
# https://unbounce.com/landing-page-articles/what-is-a-landing-page/
# Is Your Landing Page Good Enough to get into Y Combinator?
# https://yourlandingpagesucks.com/startup-landing-page-teardown-yc/
# encodeURIComponent() - JavaScript | MDN
# https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURIComponent#examples
COPY <<"EOT" /usr/share/nginx/html/index.html
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <meta
            name="description"
            content="Get WolframAlpha Pro step-by-step solution for free. Wolfree is free and open-source. (1) Type the math problem (2) Click the button (3) Read the solution"
        >
        <title>Free Wolfram Alpha Step-by-step Solution - Wolfree</title>
        <link rel="stylesheet" href="/chota.min.css">
        <style>
            :root {
                --color-primary: blue;
            }
            html {
                margin: 1rem;
            }
            body {
                line-height: 4rem;
                max-width: 30em;
                margin: auto;
                color: black;
                font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, "Noto Sans", sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol", "Noto Color Emoji";
            }
            section {
                margin: 9rem auto;
            }
            a {
                text-decoration: none;
                word-wrap: break-word;
            }
            .button, #input {
                border-radius: 3rem;
                padding: 1rem 2rem;
                margin: 1.3rem auto;
            }
            ::placeholder {
                color: black;
            }
        </style>
        <style>
            [data-wolfree-navbar] {
                line-height: 3;
                flex-flow: row wrap;
                max-width: 780px;
                display: flex;
                margin: 1rem auto;
            }
            [data-wolfree-navbar] > div {
                text-align: center;
                display: flex;
                flex: auto;
            }
            [data-wolfree-navbar] > div > a {
                font-family: sans-serif;
                text-decoration: none;
                margin: auto 0.3rem;
                flex: auto;
            }
        </style>
    </head>
    <body>
        <nav data-wolfree-navbar>
            <div>
                <a href="/">Wolfree</a>
                <a href="/input/">Input</a>
                <a href="/mirror/">Mirror</a>
            </div>
            <div>
                <a href="/#source">Source</a>
                <a href="/#fediverse">Fediverse</a>
                <a href="/dmca/">DMCA</a>
            </div>
        </nav>
        <section>
            <h1>Free Wolfram Alpha<br>Step-by-step Solution</h1>
            <p>
                Wolfree bypasses paywalls and shares step-by-step solutions.
                (It's like Sci-Hub, but Sci-Hub shares scholarly literature.)
                Wolfree is free and open-source.
            </p>
            <form
                onsubmit="
                    function encodeRFC3986URIComponent(str) {
                        return encodeURIComponent(str)
                            .replace(
                                /[!'()*]/g,
                                (c) => `%${c.charCodeAt(0).toString(16).toUpperCase()}`
                        );
                    }
                    location = '/input/?i=' + encodeRFC3986URIComponent(input.value);
                    return false;
                "
            >
                <input type=text id=input placeholder="&nbsp;Enter math problems" autofocus>
                <button type=submit class="button primary">&nbsp;<span>Show Steps</span>&nbsp;</button>
                <a href="/#how-to-use" class="button outline primary">&nbsp;<span>Learn More</span>&nbsp;</a>
            </form>
        </section>
        <section>
            <h2>How to use</h2>
            <p>
                For example, if <a href="/input/?i=y%27%3Dy">y'=y</a> is the math problem,
            </p>
            <ol>
                <li>Type y'=y in the text box above.</li>
                <li>Click the blue "Show Steps" button.</li>
                <li>Read the step-by-step solutions.</li>
            </ol>
            <p>
                If something goes wrong, try <a href="/mirror/">other mirror sites</a>.
            </p>
        </section>
        <section>
            <h2 id=mirror>Mirror</h2>
            <p>
                See the <a href="/mirror/">list of mirrors</a> for details.
                Try other mirrors when the Internet service providers have broken the Internet connection to this site.
            </p>
        </section>
        <section>
            <h2 id=fediverse>Fediverse</h2>
            <p>
                The Wolfree community on the Fediverse may post Web addresses of new mirror sites.
                Try the new mirrors when the Internet service providers have broken the Internet connection to the older mirrors.
            </p>
            <ul>
                <li><a>https://poa.st/@wolfree</a></li>
                <li><a>https://sb.bae.st/@wolfree</a></li>
                <li><a>https://kiwifarms.cc/wolfree</a></li>
                <li><a>https://spinster.xyz/@wolfree</a></li>
                <li><a>https://freespeechextremist.com/wolfree</a></li>
            </ul>
            <p>
                If your Internet service providers have broken the Internet connection to the Fediverse,
                install
                <a href="https://www.torproject.org/">Tor Browser</a>
                to circumvent censorship.
            </p>
        </section>
        <section>
            <h2 id=source>Source</h2>
            <p>
                Microsoft GitHub is unreliable due to the DMCA.
                Internet hosting services compatible with the Fediverse,
                such as ForgeFed and Gitea,
                are much more reliable than Microsoft GitHub.
                You can find the source code on the following Gitea servers.
            </p>
            <ul>
                <li><a>https://try.gitea.io/wolfree</a></li>
                <li><a>https://git.disroot.org/wolfree</a></li>
                <li><a>https://git.kiwifarms.net/wolfree</a></li>
                <li><a>http://it7otdanqu7ktntxzm427cba6i53w6wlanlh23v5i3siqmos47pzhvyd.onion/wolfree</a></li>
            </ul>
            <p>
                This program is free software: you can redistribute it and/or modify
                it under the terms of the GNU Affero General Public License as
                published by the Free Software Foundation, either version 3 of the
                License, or (at your option) any later version.
            </p>
        </section>
        <section>
            <h2 id=dmca>DMCA</h2>
            <p>
                See some <a href="/dmca/">DMCA takedown notices from Wolfram Alpha LLC</a>.
            </p>
        </section>
        <section>
            <h2>How it works</h2>
            <p>
                <a href="https://en.wikipedia.org/wiki/Internet_service_provider">Internet service providers</a>,
                Web hosting service providers,
                the website operators of the Wolfree mirror sites,
                and the programmers of the Wolfree Dockerfile can help you get Wolfram Alpha Pro step-by-step solutions for free.
                Here's how:
            </p>
            <ol>
                <li>The programmers of the Wolfree Dockerfile distribute the source code on the Fediverse, such as ForgeFed and Gitea.</li>
                <li>The website operators of the Wolfree mirror sites download the Wolfree Dockerfile from the Fediverse.</li>
                <li>Docker Engine reads the Wolfree Dockerfile and automatically configures the Web servers.</li>
                <li>Some Web hosting service providers run many Web servers and deploy the Wolfree mirror sites.</li>
                <li>Enough Internet service providers cooperate, so your Web browser can connect to the Wolfree mirror sites.</li>
                <li>You successfully read Wolfram Alpha Pro step-by-step solutions for free.</li>
            </ol>
        </section>
        <section>
            <h2>Intention</h2>
            <p>
                Get step-by-step answers and hints for your math homework problems.
                Learn the basics, check your work, and gain insight into ways to solve problems.
            </p>
            <p>
                Use step-by-step calculators for chemistry, calculus, algebra, trigonometry, and equation solving.
                Gain more understanding of your homework with steps and hints guiding you from problems to answers.
            </p>
            <p>
                The Wolfree mirror sites not only give you the answers you're looking for but also help you learn how to solve problems.
                The Wolfree mirror sites leverage the Wolfram Language to allow free-form linguistic input of computations and programs.
            </p>
            <p>
                The Wolfree mirror sites bring extensive data and computation capabilities derived from the Wolfram knowledgebase and curated data.
                The Wolfree mirror sites integrate interactive and programmatic access to the full power of the Wolfram Alpha computational knowledge engine.
            </p>
        </section>
        <section>
            <h2>Acknowledgment</h2>
            <p>
                See the <a href="/acknowledgment/">acknowledgment page</a> for details.
            </p>
        </section>
        <script>
            setTimeout(
                () => document.querySelectorAll`
                    a:not([href])
                `.forEach(
                    element => element.href = element.innerText
                )
            )
        </script>
        <script>
            setTimeout(
                () => {
                    document.querySelectorAll`
                        h1,h2
                    `.forEach(
                        element => element.id = element.innerText.toLowerCase().replaceAll(' ', '-')
                    )
                    setTimeout(
                        () => document.getElementById(location.hash.slice(1))?.scrollIntoView()
                    )
                }
            )
        </script>
    </body>
</html>
EOT


# GitHub - libredirect/instances: Automated instances list for LibRedirect
# https://github.com/libredirect/instances/blob/main/data.json
COPY <<"EOT" /libredirect/instances.json
{
    "wolfree": {
        "clearnet": [
            "https://gqq.gitlab.io/",
            "https://jqq.gitlab.io/",
            "https://rqq.gitlab.io/",
            "https://sqq.gitlab.io/",
            "https://uqq.gitlab.io/"
        ],
        "tor": [],
        "i2p": [],
        "loki": []
    }
}
EOT


COPY <<"EOT" /libredirect/index.html
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <meta
            name="description"
            content="This mirror is a modified mirror that does not bypass paywalls, so the programmers of LibRedirect can safely redirect the users of LibRedirect to this mirror."
        >
        <title>A modified mirror does not bypass paywalls.</title>
        <style>
            html {
                margin: 1rem;
            }
            body {
                line-height: 2rem;
                max-width: 30rem;
                margin: auto;
            }
            section {
                margin: 4rem auto;
            }
            a {
                text-decoration: none;
                word-wrap: break-word;
            }
            h1, h2, h3, h4, h5, h6 {
                line-height: normal;
            }
        </style>
    </head>
    <body>
        <section>
            <h1>A modified mirror does not bypass paywalls.</h1>
            <p>
                This mirror is different from most other Wolfree mirrors.
            </p>
            <p>
                The programmers of Wolfree host the source code on the Fediverse,
                while the programmers of LibRedirect host the source code on Microsoft GitHub.
                The problem is that most other Wolfree mirrors bypass paywalls,
                so the programmers of LibRedirect can not safely redirect the users of LibRedirect to most other Wolfree mirrors.
            </p>
            <p>
                This mirror is a modified mirror that does not bypass paywalls,
                so the programmers of LibRedirect can safely redirect the users of LibRedirect to this mirror.
                You can read the following issue on Microsoft GitHub.
                <a href="https://github.com/libredirect/libredirect/issues/425">https://github.com/libredirect/libredirect/issues/425</a>
            </p>
        </section>
        <section>
            <h2 id="mirror">Mirror Site</h2>
            <ul>
                <li><a href="https://gqq.gitlab.io/">https://gqq.gitlab.io/</a></li>
                <li><a href="https://jqq.gitlab.io/">https://jqq.gitlab.io/</a></li>
                <li><a href="https://rqq.gitlab.io/">https://rqq.gitlab.io/</a></li>
                <li><a href="https://sqq.gitlab.io/">https://sqq.gitlab.io/</a></li>
                <li><a href="https://uqq.gitlab.io/">https://uqq.gitlab.io/</a></li>
            </ul>
            <p>
                Machine-readable data: <a href="instances.json">instances.json</a>
            </p>
        </section>
        <section>
            <h2 id="source">Source Code</h2>
            <ul>
                <li><a href="https://try.gitea.io/wolfree">https://try.gitea.io/wolfree</a></li>
                <li><a href="https://git.disroot.org/wolfree">https://git.disroot.org/wolfree</a></li>
                <li><a href="https://git.kiwifarms.net/wolfree">https://git.kiwifarms.net/wolfree</a></li>
                <li><a href="http://it7otdanqu7ktntxzm427cba6i53w6wlanlh23v5i3siqmos47pzhvyd.onion/wolfree">http://it7otdanqu7ktntxzm427cba6i53w6wlanlh23v5i3siqmos47pzhvyd.onion/wolfree</a></li>
            </ul>
            <p>
                This program is free software: you can redistribute it and/or modify
                it under the terms of the GNU Affero General Public License as
                published by the Free Software Foundation, either version 3 of the
                License, or (at your option) any later version.
            </p>
        </section>
    </body>
</html>
EOT


COPY <<"EOT" /usr/share/nginx/html/README.md
# Wolfree Dockerfile
There are many ways to host a Wolfree mirror site.
You can use Docker or take any other approach you prefer.

## How to use Docker
1.  Install Docker.
    https://www.docker.com/

2.  Run the following command.

    ```
    docker build --progress=plain --tag wolfree https://try.gitea.io/wolfree/wolfree-dockerfile.git
    ```

3.  Run the following command.

    ```
    docker run --interactive --tty --publish 80:80 wolfree
    ```

4.  Docker Engine will output two Web addresses. For example,

    ```
    ----------------------------------------------------------------------
    Install Firefox and try:
    http://127.0.0.1/
    Install Tor Browser and try:
    http://pz7cewj2umcccjvfcviofyjcqigzgjfk3j7forlrwczrfu5zoe57vtad.onion/
    ----------------------------------------------------------------------
    ```

5.  Open Firefox and Tor browser, enter the Web addresses, and try the Wolfree mirror sites.

## Repository Mirror
You can try other Gitea servers. For example,
```
docker build --progress=plain --tag wolfree https://try.gitea.io/wolfree/wolfree-dockerfile.git
docker build --progress=plain --tag wolfree https://git.disroot.org/wolfree/wolfree-dockerfile.git
docker build --progress=plain --tag wolfree https://git.kiwifarms.net/wolfree/wolfree-dockerfile.git
docker build --progress=plain --tag wolfree http://it7otdanqu7ktntxzm427cba6i53w6wlanlh23v5i3siqmos47pzhvyd.onion/wolfree/wolfree-dockerfile.git
```

## LibRedirect
You can modify some functions to create LibRedirect-friendly mirrors.
```
sed -i 's/\/\/ f8RCUrgvdPqq//' /usr/share/nginx/html/input/wolfree.js
mv /libredirect/index.html     /usr/share/nginx/html/
mv /libredirect/instances.json /usr/share/nginx/html/
rm /usr/share/nginx/html/mirror/index.html
rm /usr/share/nginx/html/dmca/index.html
rm /usr/share/nginx/html/acknowledgment/index.html
```

## Helpful websites for new developers
The following article provides an introduction to the terminal.

https://developer.mozilla.org/en-US/docs/Learn/Tools_and_testing/Understanding_client-side_tools/Command_line

Linux distributions have a terminal available by default.
The following guide lists some recommended distributions.

https://www.privacyguides.org/desktop/

Learn JavaScript in the following MDN Learning Area.

https://developer.mozilla.org/en-US/docs/Learn

Chrome DevTools is a set of Web developer tools built directly into the Google Chrome browser.

https://developer.chrome.com/docs/devtools/
EOT


# Configure GitLab Page
COPY <<"EOT" /usr/share/nginx/html/.gitlab-ci.yml
# To contribute improvements to CI/CD templates, please follow the Development guide at:
# https://docs.gitlab.com/ee/development/cicd/templates.html
# This specific template is located at:
# https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Pages/HTML.gitlab-ci.yml

# Full project: https://gitlab.com/pages/plain-html
pages:
  stage: deploy
  environment: production
  script:
    - mkdir .public
    - cp -r ./* .public
    - rm -rf public
    - mv .public public
  artifacts:
    paths:
      - public
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
EOT


# Configure GitHub Page
# Bypassing Jekyll on GitHub Pages | The GitHub Blog
# https://github.blog/2009-12-29-bypassing-jekyll-on-github-pages/
# jekyll - Pushed .nojekyll file to Github pages, no effect? - Stack Overflow
# https://stackoverflow.com/questions/47356997/pushed-nojekyll-file-to-github-pages-no-effect
COPY <<"EOT" /usr/share/nginx/html/.nojekyll
EOT


# regular expression - Correct way to match a leading space with sed (all of them)? - Unix & Linux Stack Exchange
# https://unix.stackexchange.com/questions/426358/correct-way-to-match-a-leading-space-with-sed-all-of-them
RUN sed -i 's/^ *//' /usr/share/nginx/html/input/wolfree.js
RUN sed -i 's/^ *//' /usr/share/nginx/html/instances.json
RUN sed -i 's/^ *//' /usr/share/nginx/html/mirror/index.html
RUN sed -i 's/^ *//' /usr/share/nginx/html/dmca/index.html
RUN sed -i 's/^ *//' /usr/share/nginx/html/acknowledgment/index.html
RUN sed -i 's/^ *//' /usr/share/nginx/html/index.html
RUN sed -i 's/^ *//' /libredirect/instances.json
RUN sed -i 's/^ *//' /libredirect/index.html


COPY <<"EOT" /app/entrypoint.sh
#!/bin/sh
sudo -u toranon tor &
nginx
sleep 1
echo ----------------------------------------------------------------------
echo Install Firefox and try:
echo http://127.0.0.1/
echo Install Tor Browser and try:
echo http://$(cat /var/lib/tor/my_website/hostname)/
echo ----------------------------------------------------------------------
sh
EOT


CMD sh /app/entrypoint.sh

# SPDX-License-Identifier: AGPL-3.0-or-later

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
