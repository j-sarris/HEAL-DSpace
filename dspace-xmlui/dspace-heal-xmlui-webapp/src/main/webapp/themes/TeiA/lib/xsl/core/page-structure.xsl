<!--

    The contents of this file are subject to the license and copyright
    detailed in the LICENSE and NOTICE files at the root of the source
    tree and available online at

    http://www.dspace.org/license/

-->
<!--
    Main structure of the page, determines where
    header, footer, body, navigation are structurally rendered.
    Rendering of the header, footer, trail and alerts

    Author: art.lowel at atmire.com
    Author: lieven.droogmans at atmire.com
    Author: ben at atmire.com
    Author: Alexey Maslov

-->

<xsl:stylesheet xmlns:i18n="http://apache.org/cocoon/i18n/2.1"
                xmlns:dri="http://di.tamu.edu/DRI/1.0/"
                xmlns:mets="http://www.loc.gov/METS/"
                xmlns:xlink="http://www.w3.org/TR/xlink/"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:dim="http://www.dspace.org/xmlns/dspace/dim"
                xmlns:xhtml="http://www.w3.org/1999/xhtml"
                xmlns:mods="http://www.loc.gov/mods/v3"
                xmlns:dc="http://purl.org/dc/elements/1.1/"
                xmlns:confman="org.dspace.core.ConfigurationManager"
                xmlns="http://www.w3.org/1999/xhtml"
                exclude-result-prefixes="i18n dri mets xlink xsl dim xhtml mods dc confman">

    <xsl:import href="pages.xsl"/>

    <xsl:output indent="yes"/>

    <!--
        Requested Page URI. Some functions may alter behavior of processing depending if URI matches a pattern.
        Specifically, adding a static page will need to override the DRI, to directly add content.
    -->
    <xsl:variable name="request-uri" select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='request'][@qualifier='URI']"/>

    <!--
        Full URI of the current page. Composed of scheme, server name and port and request URI.
    -->
    <xsl:variable name="current-uri">
        <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='request'][@qualifier='scheme']"/>
        <xsl:text>://</xsl:text>
        <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='request'][@qualifier='serverName']"/>
        <xsl:text>:</xsl:text>
        <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='request'][@qualifier='serverPort']"/>
        <xsl:value-of select="$context-path"/>
        <xsl:text>/</xsl:text>
        <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='request'][@qualifier='URI']"/>
    </xsl:variable>

    <!--
        The starting point of any XSL processing is matching the root element. In DRI the root element is document,
        which contains a version attribute and three top level elements: body, options, meta (in that order).

        This template creates the html document, giving it a head and body. A title and the CSS style reference
        are placed in the html head, while the body is further split into several divs. The top-level div
        directly under html body is called "ds-main". It is further subdivided into:
            "ds-header"  - the header div containing title, subtitle, trail and other front matter
            "ds-body"    - the div containing all the content of the page; built from the contents of dri:body
            "ds-options" - the div with all the navigation and actions; built from the contents of dri:options
            "ds-footer"  - optional footer div, containing misc information

        The order in which the top level divisions appear may have some impact on the design of CSS and the
        final appearance of the DSpace page. While the layout of the DRI schema does favor the above div
        arrangement, nothing is preventing the designer from changing them around or adding new ones by
        overriding the dri:document template.
    -->
    <xsl:template match="dri:document">
        <html class="no-js">
            <!-- First of all, build the HTML head element -->
            <xsl:call-template name="buildHead"/>
            <!-- Then proceed to the body -->

            <!--paulirish.com/2008/conditional-stylesheets-vs-css-hacks-answer-neither/-->
            <xsl:text disable-output-escaping="yes">&lt;!--[if lt IE 7 ]&gt; &lt;body class="ie6"&gt; &lt;![endif]--&gt;
                &lt;!--[if IE 7 ]&gt;    &lt;body class="ie7"&gt; &lt;![endif]--&gt;
                &lt;!--[if IE 8 ]&gt;    &lt;body class="ie8"&gt; &lt;![endif]--&gt;
                &lt;!--[if IE 9 ]&gt;    &lt;body class="ie9"&gt; &lt;![endif]--&gt;
                &lt;!--[if (gt IE 9)|!(IE)]&gt;&lt;!--&gt;&lt;body&gt;&lt;!--&lt;![endif]--&gt;</xsl:text>

            <xsl:choose>
                <xsl:when test="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='framing'][@qualifier='popup']">
                    <xsl:apply-templates select="dri:body/*"/>
                </xsl:when>
                <xsl:otherwise>
                    <div id="ds-main">

                        <!--The header div, complete with title, subtitle and other junk-->
                        <xsl:call-template name="buildHeader"/>

                        <!--The trail is built by applying a template over pageMeta's trail children. -->
                        <xsl:call-template name="buildTrail"/>

                        <!--javascript-disabled warning, will be invisible if javascript is enabled-->
                        <div id="no-js-warning-wrapper" class="hidden">
                            <div id="no-js-warning">
                                <div class="notice failure">
                                    <xsl:text>JavaScript is disabled for your browser. Some features of this site may not work without it.</xsl:text>
                                </div>
                            </div>
                        </div>


                        <!--ds-content is a groups ds-body and the navigation together and used to put the clearfix on, center, etc.
                            ds-content-wrapper is necessary for IE6 to allow it to center the page content-->
                        <div id="ds-content-wrapper" class="container">
                            <div id="ds-content" class="row">
                                <!--
                               Goes over the document tag's children elements: body, options, meta. The body template
                               generates the ds-body div that contains all the content. The options template generates
                               the ds-options div that contains the navigation and action options available to the
                               user. The meta element is ignored since its contents are not processed directly, but
                               instead referenced from the different points in the document. -->
                                <xsl:apply-templates/>
                            </div>
                        </div>


                        <!--
                            The footer div, dropping whatever extra information is needed on the page. It will
                            most likely be something similar in structure to the currently given example. -->
                        <xsl:call-template name="buildFooter"/>

                    </div>

                </xsl:otherwise>
            </xsl:choose>
            <!-- Javascript at the bottom for fast page loading -->
            <xsl:call-template name="addJavascript"/>

            <xsl:text disable-output-escaping="yes">&lt;/body&gt;</xsl:text>
        </html>
    </xsl:template>

    <!-- The HTML head element contains references to CSS as well as embedded JavaScript code. Most of this
information is either user-provided bits of post-processing (as in the case of the JavaScript), or
references to stylesheets pulled directly from the pageMeta element. -->
    <xsl:template name="buildHead">
        <head>
            <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>

            <!-- Always force latest IE rendering engine (even in intranet) & Chrome Frame -->
            <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1"/>

            <!--  Mobile Viewport Fix
                  j.mp/mobileviewport & davidbcalhoun.com/2010/viewport-metatag
            device-width : Occupy full width of the screen in its current orientation
            initial-scale = 1.0 retains dimensions instead of zooming out if page height > device height
            maximum-scale = 1.0 retains dimensions instead of zooming in if page width < device width
            -->
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0"/>

            <link rel="shortcut icon">
                <xsl:attribute name="href">
                    <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                    <xsl:text>/themes/</xsl:text>
                    <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='theme'][@qualifier='path']"/>
                    <xsl:text>/images/favicon.ico</xsl:text>
                </xsl:attribute>
            </link>
            <link rel="apple-touch-icon">
                <xsl:attribute name="href">
                    <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                    <xsl:text>/themes/</xsl:text>
                    <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='theme'][@qualifier='path']"/>
                    <xsl:text>/images/apple-touch-icon.png</xsl:text>
                </xsl:attribute>
            </link>

            <meta name="Generator">
                <xsl:attribute name="content">
                    <xsl:text>DSpace</xsl:text>
                    <xsl:if test="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='dspace'][@qualifier='version']">
                        <xsl:text> </xsl:text>
                        <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='dspace'][@qualifier='version']"/>
                    </xsl:if>
                </xsl:attribute>
            </meta>
            <!-- Add stylsheets -->
            <xsl:for-each select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='stylesheet']">
                <link rel="stylesheet" type="text/css">
                    <xsl:attribute name="media">
                        <xsl:value-of select="@qualifier"/>
                    </xsl:attribute>
                    <xsl:attribute name="href">
                        <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                        <xsl:text>/themes/</xsl:text>
                        <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='theme'][@qualifier='path']"/>
                        <xsl:text>/</xsl:text>
                        <xsl:value-of select="."/>
                    </xsl:attribute>
                </link>
            </xsl:for-each>

            <!-- Add syndication feeds -->
            <xsl:for-each select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='feed']">
                <link rel="alternate" type="application">
                    <xsl:attribute name="type">
                        <xsl:text>application/</xsl:text>
                        <xsl:value-of select="@qualifier"/>
                    </xsl:attribute>
                    <xsl:attribute name="href">
                        <xsl:value-of select="."/>
                    </xsl:attribute>
                </link>
            </xsl:for-each>

            <!--  Add OpenSearch auto-discovery link -->
            <xsl:if test="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='opensearch'][@qualifier='shortName']">
                <link rel="search" type="application/opensearchdescription+xml">
                    <xsl:attribute name="href">
                        <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='request'][@qualifier='scheme']"/>
                        <xsl:text>://</xsl:text>
                        <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='request'][@qualifier='serverName']"/>
                        <xsl:text>:</xsl:text>
                        <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='request'][@qualifier='serverPort']"/>
                        <xsl:value-of select="$context-path"/>
                        <xsl:text>/</xsl:text>
                        <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='opensearch'][@qualifier='context']"/>
                        <xsl:text>description.xml</xsl:text>
                    </xsl:attribute>
                    <xsl:attribute name="title" >
                        <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='opensearch'][@qualifier='shortName']"/>
                    </xsl:attribute>
                </link>
            </xsl:if>

            <!-- The following javascript removes the default text of empty text areas when they are focused on or submitted -->
            <!-- There is also javascript to disable submitting a form when the 'enter' key is pressed. -->
            <script type="text/javascript">
                //Clear default text of emty text areas on focus
                function tFocus(element)
                {
                if (element.value == '<i18n:text>xmlui.dri2xhtml.default.textarea.value</i18n:text>'){element.value='';}
                }
                //Clear default text of emty text areas on submit
                function tSubmit(form)
                {
                var defaultedElements = document.getElementsByTagName("textarea");
                for (var i=0; i != defaultedElements.length; i++){
                if (defaultedElements[i].value == '<i18n:text>xmlui.dri2xhtml.default.textarea.value</i18n:text>'){
                defaultedElements[i].value='';}}
                }
                //Disable pressing 'enter' key to submit a form (otherwise pressing 'enter' causes a submission to start over)
                function disableEnterKey(e)
                {
                var key;

                if(window.event)
                key = window.event.keyCode;     //Internet Explorer
                else
                key = e.which;     //Firefox and Netscape

                if(key == 13)  //if "Enter" pressed, then disable!
                return false;
                else
                return true;
                }

                function FnArray()
                {
                this.funcs = new Array;
                }

                FnArray.prototype.add = function(f)
                {
                if( typeof f!= "function" )
                {
                f = new Function(f);
                }
                this.funcs[this.funcs.length] = f;
                };

                FnArray.prototype.execute = function()
                {
                for( var i=0; i <xsl:text disable-output-escaping="yes">&lt;</xsl:text> this.funcs.length; i++ )
                {
                this.funcs[i]();
                }
                };

                var runAfterJSImports = new FnArray();
            </script>

            <!-- Modernizr enables HTML5 elements & feature detects -->
            <script type="text/javascript">
                <xsl:attribute name="src">
                    <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                    <xsl:text>/themes/</xsl:text>
                    <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='theme'][@qualifier='path']"/>
                    <xsl:text>/lib/js/modernizr-1.7.min.js</xsl:text>
                </xsl:attribute>&#160;</script>
            <script type="text/javascript">
                <xsl:attribute name="src">
                    <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                    <xsl:text>/themes/</xsl:text>
                    <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='theme'][@qualifier='path']"/>
                    <xsl:text>/lib/js/jquery-1.10.2.js</xsl:text>
                </xsl:attribute>&#160;</script>
            <script type="text/javascript">
                <xsl:attribute name="src">
                    <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                    <xsl:text>/themes/</xsl:text>
                    <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='theme'][@qualifier='path']"/>
                    <xsl:text>/lib/js/jquery-ui-1.9.2.custom.min.js</xsl:text>
                </xsl:attribute>&#160;</script>


            <script type="text/javascript">
                <xsl:attribute name="src">
                    <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                    <xsl:text>/themes/</xsl:text>
                    <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='theme'][@qualifier='path']"/>
                    <xsl:text>/lib/js/bootstrap.js</xsl:text>
                </xsl:attribute>&#160;</script>

            <script type="text/javascript">
                <xsl:attribute name="src">
                    <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                    <xsl:text>/themes/</xsl:text>
                    <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='theme'][@qualifier='path']"/>
                    <xsl:text>/lib/js/modern-business.js</xsl:text>
                </xsl:attribute>&#160;</script>
            <i18n:choose>
                <i18n:when locale="en">
                    <script type="text/javascript">
                        <xsl:attribute name="src">
                            <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                            <xsl:text>/themes/</xsl:text>
                            <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='theme'][@qualifier='path']"/>
                            <xsl:text>/lib/js/jquery.ba-replacetext.js</xsl:text>
                        </xsl:attribute>&#160;</script>
                </i18n:when>
                <i18n:otherwise>
                </i18n:otherwise>
            </i18n:choose>
            <!-- Add the title in -->
            <xsl:variable name="page_title" select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='title']" />
            <title>
                <i18n:text>xmlui.general.dspace_name</i18n:text> -
                <xsl:choose>
                    <xsl:when test="starts-with($request-uri, 'page/')">
                        <xsl:choose>
                            <xsl:when test="$request-uri = 'page/about'">
                                <i18n:text>xmlui.dri2xhtml.structural.about-link</i18n:text>
                            </xsl:when>
                            <xsl:when test="$request-uri = 'page/open-data'">
                                <xsl:text>Open Data</xsl:text>
                            </xsl:when>
                            <xsl:when test="$request-uri = 'page/policies'">
                                <i18n:text>xmlui.dri2xhtml.structural.policies-link</i18n:text>
                            </xsl:when>
                            <xsl:when test="$request-uri = 'page/faq'">
                                <i18n:text>xmlui.dri2xhtml.structural.faq-link</i18n:text>
                            </xsl:when>
                            <xsl:when test="$request-uri = 'page/404'">
                                <i18n:text>xmlui.PageNotFound.title</i18n:text>
                            </xsl:when>
                            <xsl:when test="$request-uri = 'page/500'">
                                <i18n:text>xmlui.general.error.internal-error</i18n:text>
                            </xsl:when>
                            <xsl:otherwise>
                                <i18n:text>xmlui.PageNotFound.title</i18n:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="not($page_title)">
                        <xsl:text>  </xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:copy-of select="$page_title/node()" />
                    </xsl:otherwise>
                </xsl:choose>
            </title>

            <!-- Head metadata in item pages -->
            <xsl:if test="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='xhtml_head_item']">
                <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='xhtml_head_item']"
                              disable-output-escaping="yes"/>
            </xsl:if>

            <!-- Add all Google Scholar Metadata values -->
            <xsl:for-each select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[substring(@element, 1, 9) = 'citation_']">
                <meta name="{@element}" content="{.}"></meta>
            </xsl:for-each>

        </head>
    </xsl:template>


    <!-- The header (distinct from the HTML head element) contains the title, subtitle, login box and various
        placeholders for header images -->
    <xsl:template name="buildHeader">
        <nav class="navbar navbar-inverse navbar-fixed-top" role="navigation">
            <div class="container">
                <div class="navbar-header">
                    <button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".navbar-ex1-collapse">
                        <span class="sr-only">Toggle navigation</span>
                        <span class="icon-bar">&#160;</span>
                        <span class="icon-bar">&#160;</span>
                        <span class="icon-bar">&#160;</span>
                    </button>

                    <a class="navbar-brand" >
                        <xsl:attribute name="href">
                            <xsl:value-of
                                    select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                            <xsl:text>/</xsl:text>
                        </xsl:attribute>
                        ΤΕΙ Αθήνας</a>
                </div>

                <!-- Collect the nav links, forms, and other content for toggling -->
                <!-- Collect the nav links, forms, and other content for toggling -->
                <div class="collapse navbar-collapse navbar-ex1-collapse">
                    <ul class="nav navbar-nav navbar-right">
                        <xsl:choose>
                            <xsl:when test="/dri:document/dri:meta/dri:userMeta/@authenticated = 'yes'">


                                <!--<li><a>
                                    <xsl:attribute name="href">
                                        <xsl:value-of select="/dri:document/dri:meta/dri:userMeta/
                                        dri:metadata[@element='identifier' and @qualifier='vaURL']"/>
                                    </xsl:attribute>
                                    <i18n:text>xmlui.dri2xhtml.structural.logout</i18n:text>
                                </a></li>-->

                                <xsl:if test="/dri:document/dri:options/dri:list[@n='context']/dri:item">
                                    <li class="dropdown">
                                        <a data-toggle="dropdown" class="dropdown-toggle" href="#">
                                            <span class="glyphicon glyphicon-cog">&#x00AD;</span>
                                            <xsl:text>&#160;</xsl:text>
                                            <i18n:text>xmlui.administrative.eperson.ManageEPeopleMain.actions_head</i18n:text>
                                            <xsl:text>&#160;</xsl:text>
                                            <label class="caret"/></a>

                                        <ul class="dropdown-menu">
                                            <xsl:for-each select="/dri:document/dri:options/dri:list[@n='context']/dri:item/dri:xref">
                                                <li><a>
                                                    <xsl:attribute name="href">
                                                        <xsl:value-of select="@target"/>
                                                    </xsl:attribute> <i18n:text><xsl:value-of select="."/></i18n:text></a></li>
                                            </xsl:for-each>
                                        </ul>
                                    </li>
                                </xsl:if>
                                <xsl:if test="/dri:document/dri:options/dri:list/dri:list[@n='epeople']">
                                    <li class="dropdown">
                                        <a data-toggle="dropdown" class="dropdown-toggle" href="#">
                                            <i18n:text>xmlui.administrative.Navigation.administrative_access_control</i18n:text>
                                            <xsl:text>&#160;</xsl:text>
                                            <label class="caret"/></a>

                                        <ul class="dropdown-menu">
                                            <xsl:for-each select="/dri:document/dri:options/dri:list/dri:list[@n='epeople']/dri:item/dri:xref">
                                                <li><a>
                                                    <xsl:attribute name="href">
                                                        <xsl:value-of select="@target"/>
                                                    </xsl:attribute> <i18n:text><xsl:value-of select="."/></i18n:text></a></li>
                                            </xsl:for-each>
                                        </ul>
                                    </li>
                                </xsl:if>

                                <xsl:if test="/dri:document/dri:options/dri:list[@n='administrative']">
                                    <li class="dropdown">
                                        <a data-toggle="dropdown" class="dropdown-toggle" href="#">
                                            <span class="glyphicon glyphicon-wrench">&#x00AD;</span>
                                            <xsl:text>&#160;</xsl:text>
                                            <i18n:text>xmlui.administrative.Navigation.administrative_head</i18n:text>
                                            <xsl:text>&#160;</xsl:text>
                                            <label class="caret"/></a>

                                        <ul class="dropdown-menu">
                                            <xsl:for-each select="/dri:document/dri:options/dri:list[@n='administrative']/dri:item/dri:xref">
                                                <li><a>
                                                    <xsl:attribute name="href">
                                                        <xsl:value-of select="@target"/>
                                                    </xsl:attribute>
                                                    <i18n:text><xsl:value-of select="."/></i18n:text></a></li>
                                            </xsl:for-each>
                                            <li class="divider"></li>
                                            <xsl:for-each select="/dri:document/dri:options/dri:list[@n='statistics']/dri:item/dri:xref">
                                                <li><a>
                                                    <xsl:attribute name="href">
                                                        <xsl:value-of select="@target"/>
                                                    </xsl:attribute>
                                                    <i18n:text><xsl:value-of select="."/></i18n:text></a></li>
                                            </xsl:for-each>
                                            <li class="divider"></li>
                                            <xsl:for-each select="/dri:document/dri:options/dri:list/dri:list[@n='registries']/dri:item/dri:xref">
                                                <li><a>
                                                    <xsl:attribute name="href">
                                                        <xsl:value-of select="@target"/>
                                                    </xsl:attribute> <i18n:text><xsl:value-of select="."/></i18n:text></a></li>
                                            </xsl:for-each>
                                        </ul>
                                    </li>

                                </xsl:if>
                                <li class="dropdown">
                                    <a data-toggle="dropdown" class="dropdown-toggle" href="#">
                                        <span class="glyphicon glyphicon-user">&#x00AD;</span>
                                        <xsl:text>&#160;</xsl:text>
                                        <!--<i18n:text>xmlui.dri2xhtml.structural.profile</i18n:text>-->
                                        <xsl:value-of select="/dri:document/dri:meta/dri:userMeta/
                                                                    dri:metadata[@element='identifier' and @qualifier='firstName']"/>
                                        <xsl:text> </xsl:text>
                                        <xsl:value-of select="/dri:document/dri:meta/dri:userMeta/
                                                                    dri:metadata[@element='identifier' and @qualifier='lastName']"/><xsl:text>&#160;</xsl:text><label class="caret"/></a>

                                    <ul class="dropdown-menu">
                                        <li><a>
                                            <xsl:attribute name="href">
                                                <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                                                <xsl:text>/user/</xsl:text>
                                                <xsl:value-of select="/dri:document/dri:meta/dri:userMeta/dri:metadata[@element='identifier'][not(@qualifier)]"/>
                                            </xsl:attribute>
                                            <i18n:text>xmlui.dri2xhtml.structural.profile</i18n:text>
                                        </a></li>
                                        <li><a>
                                            <xsl:attribute name="href">
                                                <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                                                <xsl:text>/submissions</xsl:text>
                                            </xsl:attribute>
                                            <i18n:text>xmlui.Submission.Navigation.submissions</i18n:text>
                                        </a></li>
                                        <xsl:if test="/dri:document/dri:options/dri:list/dri:item/dri:xref[contains(@target,'/admin/export')]">
                                            <li><a>
                                                <xsl:attribute name="href">
                                                    <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                                                    <xsl:text>/admin/export</xsl:text>
                                                </xsl:attribute>
                                                <i18n:text>xmlui.administrative.Navigation.account_export</i18n:text>
                                            </a></li>
                                        </xsl:if>
                                        <li><a>
                                            <xsl:attribute name="href">
                                                <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                                                <xsl:text>/interests</xsl:text>
                                            </xsl:attribute>
                                            <i18n:text>xmlui.MyIR.AcademicInterests.title</i18n:text>
                                        </a></li>
                                        <li><a>
                                            <xsl:attribute name="href">
                                                <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                                                <xsl:text>/favorites</xsl:text>
                                            </xsl:attribute>
                                            <i18n:text>xmlui.MyIR.Favorites.title</i18n:text>
                                        </a></li>
                                        <li><a>
                                            <xsl:attribute name="href">
                                                <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                                                <xsl:text>/production</xsl:text>
                                            </xsl:attribute>
                                            <i18n:text>xmlui.MyIR.Authorship.title</i18n:text>
                                        </a></li>
                                        <li class="divider"></li>
                                        <li><a>
                                            <xsl:attribute name="href">
                                                <xsl:value-of select="/dri:document/dri:meta/dri:userMeta/dri:metadata[@element='identifier' and @qualifier='url']"/>
                                            </xsl:attribute>
                                            <i18n:text>xmlui.EPerson.Navigation.my_account</i18n:text>
                                        </a></li>
                                        <li><a>
                                            <xsl:attribute name="href">
                                                <xsl:value-of select="/dri:document/dri:meta/dri:userMeta/dri:metadata[@element='identifier' and @qualifier='logoutURL']"/>
                                            </xsl:attribute>
                                            <i18n:text>xmlui.dri2xhtml.structural.logout</i18n:text>
                                        </a></li>
                                    </ul>
                                </li>
                            </xsl:when>
                            <xsl:otherwise>
                                <li><a> <xsl:attribute name="href">
                                    <xsl:value-of select="/dri:document/dri:meta/dri:userMeta/
                                        dri:metadata[@element='identifier' and @qualifier='loginURL']"/>
                                </xsl:attribute>
                                    <i18n:text>xmlui.dri2xhtml.structural.login</i18n:text></a></li>

                            </xsl:otherwise>
                        </xsl:choose>

                    </ul>
                </div><!-- /.navbar-collapse -->

            </div><!-- /.container -->
        </nav>

        <!-- large main banner -->
        <div id="ds-banner" class="container">
            <div class="col-lg-12">
                <a>
                    <xsl:attribute name="href">
                        <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                        <xsl:text>/</xsl:text>
                    </xsl:attribute>
                    <i18n:choose>
                        <i18n:when locale="en">
                            <img>
                                <xsl:attribute name="src">
                                    <xsl:value-of select="concat($theme-path, '/images/hypatia_en.png')"/>
                                </xsl:attribute>
                            </img>
                        </i18n:when>
                        <i18n:when locale="el">
                            <img>
                                <xsl:attribute name="src">
                                    <xsl:value-of select="concat($theme-path, '/images/hypatia_el.png')"/>
                                </xsl:attribute>
                            </img>
                        </i18n:when>
                    </i18n:choose>
                </a>
            </div>
        </div>

        <!-- <div id="ds-header-wrapper">
            <div id="ds-header" class="clearfix">
                <a id="ds-header-logo-link">
                    <xsl:attribute name="href">
                        <xsl:value-of
                                select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                        <xsl:text>/</xsl:text>
                    </xsl:attribute>
                    <span id="ds-header-logo">&#160;</span>
                    <span id="ds-header-logo-text">HEAL DSpace</span>
                </a>
                <h1 class="pagetitle visuallyhidden">
                    <xsl:choose>
                        
                        <xsl:when test="not(/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='title'])">
                            <xsl:text> </xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:copy-of
                                    select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='title']/node()"/>
                        </xsl:otherwise>
                    </xsl:choose>

                </h1>
                <h2 class="static-pagetitle visuallyhidden">
                    <i18n:text>xmlui.dri2xhtml.structural.head-subtitle</i18n:text>
                </h2>


                <xsl:choose>
                    <xsl:when test="/dri:document/dri:meta/dri:userMeta/@authenticated = 'yes'">
                        <div id="ds-user-box">
                            <p>
                                <a>
                                    <xsl:attribute name="href">
                                        <xsl:value-of select="/dri:document/dri:meta/dri:userMeta/
                                        dri:metadata[@element='identifier' and @qualifier='url']"/>
                                    </xsl:attribute>
                                    <i18n:text>xmlui.dri2xhtml.structural.profile</i18n:text>
                                    <xsl:value-of select="/dri:document/dri:meta/dri:userMeta/
                                    dri:metadata[@element='identifier' and @qualifier='firstName']"/>
                                    <xsl:text> </xsl:text>
                                    <xsl:value-of select="/dri:document/dri:meta/dri:userMeta/
                                    dri:metadata[@element='identifier' and @qualifier='lastName']"/>
                                </a>
                                <xsl:text> | </xsl:text>
                                <a>
                                    <xsl:attribute name="href">
                                        <xsl:value-of select="/dri:document/dri:meta/dri:userMeta/
                                        dri:metadata[@element='identifier' and @qualifier='logoutURL']"/>
                                    </xsl:attribute>
                                    <i18n:text>xmlui.dri2xhtml.structural.logout</i18n:text>
                                </a>
                            </p>
                        </div>
                    </xsl:when>
                    <xsl:otherwise>
                        <div id="ds-user-box">
                            <p>
                                <a>
                                    <xsl:attribute name="href">
                                        <xsl:value-of select="/dri:document/dri:meta/dri:userMeta/
                                        dri:metadata[@element='identifier' and @qualifier='loginURL']"/>
                                    </xsl:attribute>
                                    <i18n:text>xmlui.dri2xhtml.structural.login</i18n:text>
                                </a>
                            </p>
                        </div>
                    </xsl:otherwise>
                </xsl:choose>

            </div>
        </div>-->
    </xsl:template>


    <!-- The header (distinct from the HTML head element) contains the title, subtitle, login box and various
        placeholders for header images -->
    <xsl:template name="buildTrail">
        <div id="ds-trail-wrapper" class="container">
            <div class="row">
                <div class="col-lg-12">
                    <div class="breadcrumb">
                        <!--  modified by aanagnostopoulos -->
                        <!-- Display a language selection if more than 1 language is supported -->
                        <xsl:if test="count(/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='page'][@qualifier='supportedLocale']) &gt; 1">
                            <div id="ds-language-selection">
                                <xsl:for-each select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='page'][@qualifier='supportedLocale']">
                                    <xsl:variable name="locale" select="."/>
                                    <a>
                                        <xsl:attribute name="href">
                                            <xsl:choose>
                                                <xsl:when test="$request-uri=''">
                                                    <xsl:value-of select="concat($context-path,'/?locale-attribute=')"/>
                                                    <xsl:value-of select="$locale"/>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:value-of select="$current-uri"/>
                                                    <xsl:text>?locale-attribute=</xsl:text>
                                                    <xsl:value-of select="$locale"/>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:attribute>
                                        <img>
                                            <xsl:attribute name="src">
                                                <xsl:value-of select="concat($theme-path,'/images/lang/', $locale, '.png')"/>
                                            </xsl:attribute>
                                            <xsl:attribute name="title">
                                                <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='supportedLocale'][@qualifier=$locale]"/>
                                            </xsl:attribute>
                                        </img>
                                    </a>
                                    <xsl:if test="position() != last()">
                                        <xsl:text>&#160;</xsl:text>
                                    </xsl:if>
                                </xsl:for-each>
                            </div>
                        </xsl:if>
                        <!-- END aanagnostopoulos -->
                        <ul id="ds-trail">
                            <xsl:choose>
                                <xsl:when test="starts-with($request-uri, 'page/')">
                                    <xsl:choose>
                                        <xsl:when test="starts-with($request-uri, 'page/about')">
                                            <li class="ds-trail-link first-link ">
                                                <a>
                                                    <xsl:attribute name="href">
                                                        <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                                                    </xsl:attribute>
                                                    <i18n:text>xmlui.general.dspace_home</i18n:text>
                                                </a>
                                            </li>
                                            <li class="ds-trail-arrow">/</li>
                                            <li class="ds-trail-link last-link">
                                                <i18n:text>xmlui.dri2xhtml.structural.about-link</i18n:text>
                                            </li>
                                        </xsl:when>
                                        <xsl:when test="starts-with($request-uri, 'page/open-data')">
                                            <li class="ds-trail-link first-link ">
                                                <a>
                                                    <xsl:attribute name="href">
                                                        <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                                                    </xsl:attribute>
                                                    <i18n:text>xmlui.general.dspace_home</i18n:text>
                                                </a>
                                            </li>
                                            <li class="ds-trail-arrow">/</li>
                                            <li class="ds-trail-link last-link">
                                                <xsl:text>Open Data</xsl:text>
                                            </li>
                                        </xsl:when>
                                        <xsl:when test="starts-with($request-uri, 'page/policies')">
                                            <li class="ds-trail-link first-link ">
                                                <a>
                                                    <xsl:attribute name="href">
                                                        <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                                                    </xsl:attribute>
                                                    <i18n:text>xmlui.general.dspace_home</i18n:text>
                                                </a>
                                            </li>
                                            <li class="ds-trail-arrow">/</li>
                                            <li class="ds-trail-link last-link">
                                                <i18n:text>xmlui.dri2xhtml.structural.policies-link</i18n:text>
                                            </li>
                                        </xsl:when>
                                        <xsl:when test="starts-with($request-uri, 'page/faq')">
                                            <li class="ds-trail-link first-link ">
                                                <a>
                                                    <xsl:attribute name="href">
                                                        <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                                                    </xsl:attribute>
                                                    <i18n:text>xmlui.general.dspace_home</i18n:text>
                                                </a>
                                            </li>
                                            <li class="ds-trail-arrow">/</li>
                                            <li class="ds-trail-link last-link">
                                                <i18n:text>xmlui.dri2xhtml.structural.faq-link</i18n:text>
                                            </li>
                                        </xsl:when>
                                        <xsl:when test="starts-with($request-uri, 'page/404')">
                                            <li class="ds-trail-link">
                                                <i18n:text>xmlui.administrative.registries.EditMetadataSchema.error</i18n:text>
                                            </li>
                                        </xsl:when>
                                        <xsl:when test="starts-with($request-uri, 'page/500')">
                                            <li class="ds-trail-link">
                                                <i18n:text>xmlui.administrative.registries.EditMetadataSchema.error</i18n:text>
                                            </li>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <li class="ds-trail-link">
                                                <i18n:text>xmlui.administrative.registries.EditMetadataSchema.error</i18n:text>
                                            </li>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:when>
                                <xsl:when test="count(/dri:document/dri:meta/dri:pageMeta/dri:trail) = 0">
                                    <li class="ds-trail-link first-link">-</li>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:apply-templates select="/dri:document/dri:meta/dri:pageMeta/dri:trail"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </ul>
                    </div>
                </div>
            </div>
        </div>
    </xsl:template>

    <xsl:template match="dri:trail">
        <!--put an arrow between the parts of the trail-->
        <xsl:if test="position()>1">
            <li class="ds-trail-arrow">
                <xsl:text>/</xsl:text>
            </li>
        </xsl:if>
        <li>
            <xsl:attribute name="class">
                <xsl:text>ds-trail-link </xsl:text>
                <xsl:if test="position()=1">
                    <xsl:text>first-link </xsl:text>
                </xsl:if>
                <xsl:if test="position()=last()">
                    <xsl:text>last-link</xsl:text>
                </xsl:if>
            </xsl:attribute>
            <!-- Determine whether we are dealing with a link or plain text trail link -->
            <xsl:choose>
                <xsl:when test="./@target">
                    <a>
                        <xsl:attribute name="href">
                            <xsl:value-of select="./@target"/>
                        </xsl:attribute>
                        <xsl:apply-templates />
                    </a>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates />
                </xsl:otherwise>
            </xsl:choose>
        </li>
    </xsl:template>

    <xsl:template name="cc-license">
        <xsl:param name="metadataURL"/>
        <xsl:variable name="externalMetadataURL">
            <xsl:text>cocoon:/</xsl:text>
            <xsl:value-of select="$metadataURL"/>
            <xsl:text>?sections=dmdSec,fileSec&amp;fileGrpTypes=THUMBNAIL</xsl:text>
        </xsl:variable>

        <xsl:variable name="ccLicenseName"
                      select="document($externalMetadataURL)//dim:field[@element='rights']"
                />
        <xsl:variable name="ccLicenseUri"
                      select="document($externalMetadataURL)//dim:field[@element='rights'][@qualifier='uri']"
                />
        <xsl:variable name="handleUri">
            <xsl:for-each select="document($externalMetadataURL)//dim:field[@element='identifier' and @qualifier='uri']">
                <a>
                    <xsl:attribute name="href">
                        <xsl:copy-of select="./node()"/>
                    </xsl:attribute>
                    <xsl:copy-of select="./node()"/>
                </a>
                <xsl:if test="count(following-sibling::dim:field[@element='identifier' and @qualifier='uri']) != 0">
                    <xsl:text>, </xsl:text>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>

        <xsl:if test="$ccLicenseName and $ccLicenseUri and contains($ccLicenseUri, 'creativecommons')">
            <div about="{$handleUri}">
                <xsl:attribute name="style">
                    <xsl:text>margin:0em 2em 0em 2em; padding-bottom:0em;</xsl:text>
                </xsl:attribute>
                <a rel="license"
                   href="{$ccLicenseUri}"
                   alt="{$ccLicenseName}"
                   title="{$ccLicenseName}"
                        >
                    <img>
                        <xsl:attribute name="src">
                            <xsl:value-of select="concat($theme-path,'/images/cc-ship.gif')"/>
                        </xsl:attribute>
                        <xsl:attribute name="alt">
                            <xsl:value-of select="$ccLicenseName"/>
                        </xsl:attribute>
                        <xsl:attribute name="style">
                            <xsl:text>float:left; margin:0em 1em 0em 0em; border:none;</xsl:text>
                        </xsl:attribute>
                    </img>
                </a>
                <span>
                    <xsl:attribute name="style">
                        <xsl:text>vertical-align:middle; text-indent:0 !important;</xsl:text>
                    </xsl:attribute>
                    <i18n:text>xmlui.dri2xhtml.METS-1.0.cc-license-text</i18n:text>
                    <xsl:value-of select="$ccLicenseName"/>
                </span>
            </div>
        </xsl:if>
    </xsl:template>

    <!-- Like the header, the footer contains various miscellanious text, links, and image placeholders -->
    <xsl:template name="buildFooter">
        <div id="ds-footer-wrapper" class="container">
            <div id="ds-footer">
                <div class="row">
                    <div class="col-lg-7 pub">
                        <a href="http://dlproject.library.teiath.gr/index.html" target="_blank">
                            <img>
                                <xsl:attribute name="src">
                                    <xsl:value-of select="concat($theme-path,'/images/logo_L2_cropped_transparent.png')"/>
                                </xsl:attribute>
                            </img>
                        </a>
                        <a href="http://www.digitalplan.gov.gr/portal/" target="_blank">
                            <img>
                                <xsl:attribute name="src">
                                    <xsl:value-of select="concat($theme-path,'/images/footer-psifiaki.gif')"/>
                                </xsl:attribute>
                            </img>
                        </a>
                        <a href="http://europa.eu/legislation_summaries/agriculture/general_framework/g24234_el.htm" target="_blank">
                            <img>
                                <xsl:attribute name="src">
                                    <xsl:value-of select="concat($theme-path,'/images/footer-eu.jpg')"/>
                                </xsl:attribute>
                            </img>
                        </a>
                        <a href="http://www.espa.gr/el/Pages/Default.aspx" target="_blank">
                            <img>
                                <xsl:attribute name="src">
                                    <xsl:value-of select="concat($theme-path,'/images/footer-espa.jpg')"/>
                                </xsl:attribute>
                            </img>
                        </a>
                        <a href="http://www.teiath.gr/" target="_blank">
                            <img>
                                <xsl:attribute name="src">
                                    <xsl:value-of select="concat($theme-path,'/images/footer-teia.gif')"/>
                                </xsl:attribute>
                            </img>
                        </a>
                    </div>
                    <div class="col-lg-5 text-right">
                        <p class="promo">
                            <i18n:text>xmlui.dri2xhtml.structural.footer-promotional</i18n:text>
                        </p>

                        <div class="powered-by">&#169; 2014
                            <a href="http://www.dspace.org/" target="_blank">DSpace Software</a>
                            <xsl:text>&#160;</xsl:text>
                            <span class="theme-by">Powered by</span>
                            <a target="_blank" href="http://www.imc.com.gr">IMC Technologies</a>
                        </div>
                    </div>

                </div>
                <div class="row">
                    <div class="col-lg-12">
                        <div class="text-center">
                            <a>
                                <xsl:attribute name="href">
                                    <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                                </xsl:attribute>
                                <i18n:text>xmlui.general.dspace_home</i18n:text>
                            </a>
                            <xsl:text> | </xsl:text>
                            <a>
                                <xsl:attribute name="href">
                                    <xsl:value-of
                                            select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                                    <xsl:text>/page/about</xsl:text>
                                </xsl:attribute>
                                <i18n:text>xmlui.dri2xhtml.structural.about-link</i18n:text>
                            </a>
                            <xsl:text> | </xsl:text>
                            <a>
                                <xsl:attribute name="href">
                                    <xsl:value-of
                                            select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                                    <xsl:text>/feedback</xsl:text>
                                </xsl:attribute>
                                <i18n:text>xmlui.dri2xhtml.structural.contact-link</i18n:text>
                            </a>
                            <!--<xsl:text> | </xsl:text>
                            <a>
                                <xsl:attribute name="href">
                                    <xsl:value-of
                                            select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                                    <xsl:text>/feedback</xsl:text>
                                </xsl:attribute>
                                <i18n:text>xmlui.dri2xhtml.structural.feedback-link</i18n:text>
                            </a> -->
                        </div>
                    </div>
                </div>
                <!--Invisible link to HTML sitemap (for search engines) -->
                <a class="hidden">
                    <xsl:attribute name="href">
                        <xsl:value-of
                                select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                        <xsl:text>/htmlmap</xsl:text>
                    </xsl:attribute>
                    <xsl:text>&#160;</xsl:text>
                </a>
            </div>
        </div>
    </xsl:template>


    <!--
            The meta, body, options elements; the three top-level elements in the schema
    -->




    <!--
        The template to handle the dri:body element. It simply creates the ds-body div and applies
        templates of the body's child elements (which consists entirely of dri:div tags).
    -->
    <xsl:template match="dri:body">
        <div id="ds-body" class="col-md-9">
            <xsl:if test="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='alert'][@qualifier='message']">
                <div id="alert alert-info">
                    <p>
                        <xsl:copy-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='alert'][@qualifier='message']/node()"/>
                    </p>
                </div>
            </xsl:if>

            <!-- Check for the custom pages -->
            <xsl:choose>
                <xsl:when test="starts-with($request-uri, 'page/')">
                    <xsl:apply-templates />
                </xsl:when>
                <!-- Otherwise use default handling of body -->
                <xsl:otherwise>
                    <xsl:apply-templates />
                </xsl:otherwise>
            </xsl:choose>

        </div>
    </xsl:template>

    <!-- Remove search DSpace from home page body -->
    <xsl:template name="disable_front-page-search" match="dri:div[@id='aspect.discovery.SiteViewer.div.front-page-search']">
    </xsl:template>

    <!-- Front page richer content -->
    <xsl:template match="dri:div[@id='file.news.div.news']">

        <h2 class="page-header"><i18n:text>xmlui.general.welcome</i18n:text></h2>
        <div class="row">
            <div class="col-lg-12">
                <img>
                    <xsl:attribute name="src">
                        <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                        <xsl:text>/themes/</xsl:text>
                        <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='theme'][@qualifier='path']"/>
                        <xsl:text>/images/front/front_02.jpg</xsl:text>
                    </xsl:attribute>
                    <xsl:attribute name="class">img-responsive</xsl:attribute>
                </img>
            </div>
        </div>
        <br/>
        <div class="row">
            <div class="col-lg-12 text-justify">
                <i18n:text>xmlui.feed.general-description</i18n:text>
            </div>
        </div>
        <!--    	<xsl:apply-templates />	-->
    </xsl:template>

    <!-- Currently the dri:meta element is not parsed directly. Instead, parts of it are referenced from inside
        other elements (like reference). The blank template below ends the execution of the meta branch -->
    <xsl:template match="dri:meta">
    </xsl:template>

    <!-- Meta's children: userMeta, pageMeta, objectMeta and repositoryMeta may or may not have templates of
        their own. This depends on the meta template implementation, which currently does not go this deep.
    <xsl:template match="dri:userMeta" />
    <xsl:template match="dri:pageMeta" />
    <xsl:template match="dri:objectMeta" />
    <xsl:template match="dri:repositoryMeta" />
    -->

    <xsl:template name="addJavascript">
        <xsl:variable name="jqueryVersion">
            <xsl:text>1.10.2</xsl:text>
        </xsl:variable>

        <xsl:variable name="protocol">
            <xsl:choose>
                <xsl:when test="starts-with(confman:getProperty('dspace.baseUrl'), 'https://')">
                    <xsl:text>https://</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>http://</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- <script type="text/javascript" src="{concat($protocol, 'ajax.googleapis.com/ajax/libs/jquery/', $jqueryVersion ,'/jquery.min.js')}">&#160;</script>

      <xsl:variable name="localJQuerySrc">
          <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
          <xsl:text>/static/js/jquery-</xsl:text>
          <xsl:value-of select="$jqueryVersion"/>
          <xsl:text>.min.js</xsl:text>
      </xsl:variable>

      <script type="text/javascript">
          <xsl:text disable-output-escaping="yes">!window.jQuery &amp;&amp; document.write('&lt;script type="text/javascript" src="</xsl:text><xsl:value-of
              select="$localJQuerySrc"/><xsl:text disable-output-escaping="yes">"&gt;&#160;&lt;\/script&gt;')</xsl:text>
      </script>  -->



        <!-- Add theme javascipt  -->
        <xsl:for-each select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='javascript'][not(@qualifier)]">
            <script type="text/javascript">
                <xsl:attribute name="src">
                    <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                    <xsl:text>/themes/</xsl:text>
                    <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='theme'][@qualifier='path']"/>
                    <xsl:text>/</xsl:text>
                    <xsl:value-of select="."/>
                </xsl:attribute>&#160;</script>
        </xsl:for-each>

        <!-- add "shared" javascript from static, path is relative to webapp root-->
        <xsl:for-each select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='javascript'][@qualifier='static']">
            <!--This is a dirty way of keeping the scriptaculous stuff from choice-support
            out of our theme without modifying the administrative and submission sitemaps.
            This is obviously not ideal, but adding those scripts in those sitemaps is far
            from ideal as well-->
            <xsl:choose>
                <xsl:when test="text() = 'static/js/choice-support.js'">
                    <script type="text/javascript">
                        <xsl:attribute name="src">
                            <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                            <xsl:text>/themes/</xsl:text>
                            <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='theme'][@qualifier='path']"/>
                            <xsl:text>/lib/js/choice-support.js</xsl:text>
                        </xsl:attribute>&#160;</script>
                </xsl:when>
                <!-- remove search.js -->
                <xsl:when test="text() = 'static/js/discovery/search/search.js'">
                    <xsl:text>&#160;</xsl:text>
                </xsl:when>
                <xsl:when test="not(starts-with(text(), 'static/js/scriptaculous'))">
                    <script type="text/javascript">
                        <xsl:attribute name="src">
                            <xsl:value-of
                                    select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                            <xsl:text>/</xsl:text>
                            <xsl:value-of select="."/>
                        </xsl:attribute>&#160;</script>
                </xsl:when>
            </xsl:choose>
        </xsl:for-each>

        <!-- add setup JS code if this is a choices lookup page -->
        <xsl:if test="dri:body/dri:div[@n='lookup']">
            <xsl:call-template name="choiceLookupPopUpSetup"/>
        </xsl:if>

        <!--PNG Fix for IE6-->
        <xsl:text disable-output-escaping="yes">&lt;!--[if lt IE 7 ]&gt;</xsl:text>
        <script type="text/javascript">
            <xsl:attribute name="src">
                <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                <xsl:text>/themes/</xsl:text>
                <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='theme'][@qualifier='path']"/>
                <xsl:text>/lib/js/DD_belatedPNG_0.0.8a.js?v=1</xsl:text>
            </xsl:attribute>&#160;</script>
        <script type="text/javascript">
            <xsl:text>DD_belatedPNG.fix('#ds-header-logo');DD_belatedPNG.fix('#ds-footer-logo');$.each($('img[src$=png]'), function() {DD_belatedPNG.fixPng(this);});</xsl:text>
        </script>
        <xsl:text disable-output-escaping="yes" >&lt;![endif]--&gt;</xsl:text>


        <script type="text/javascript">
            runAfterJSImports.execute();
        </script>

        <!-- Add a google analytics script if the key is present -->
        <xsl:if test="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='google'][@qualifier='analytics']">
            <script type="text/javascript"><xsl:text>
                   var _gaq = _gaq || [];
                   _gaq.push(['_setAccount', '</xsl:text><xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='google'][@qualifier='analytics']"/><xsl:text>']);
                   _gaq.push(['_trackPageview']);

                   (function() {
                       var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
                       ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
                       var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
                   })();
           </xsl:text></script>
        </xsl:if>

        <!-- modified by aanagnostopoulos: added external autocomplete service (Triple store)-->

        <xsl:if test="/dri:document/dri:body/dri:div/dri:list[@type='form']/dri:item/dri:field[@id='aspect.submission.StepTransformer.field.dc_subject']">
            <script type="text/javascript">
        <xsl:text>
			$(function() {

                    var healKeywordField = 'aspect_submission_StepTransformer_field_dc_subject';
                    var healKeywordQualifier = $('#'+healKeywordField+'_qualifier');

					var healKeywordAC = $('#'+healKeywordField+'_value').autocomplete({
						source: "</xsl:text><xsl:value-of select="concat($context-path,'/JSON/rdf/search/keywords')"/><xsl:text>",
						minLength: 3,
						open: function() { 
					        $('#'+healKeywordField+'_value').autocomplete("widget").width(600)
					    }  
					});

                    healKeywordQualifier.change(function() {
						var qualifier = $(this).val();
						var acSource = '</xsl:text><xsl:value-of select="concat($context-path,'/JSON/rdf/search/keywords')"/><xsl:text>' + '?vocab=' + qualifier;
						healKeywordAC.autocomplete("option","source",acSource);
						//console.log(healKeywordAC.autocomplete("option", "source"));
					});

                    healKeywordQualifier.find('option:first').attr("selected", true).trigger('change');

				});</xsl:text>
            </script>
        </xsl:if>
        <xsl:if test="/dri:document/dri:body/dri:div/dri:list[@type='form']/dri:item/dri:field[@id='aspect.submission.StepTransformer.field.heal_classification']">
            <script type="text/javascript">
        <xsl:text>
			$(function() {

                    var healClassificationField = 'aspect_submission_StepTransformer_field_heal_classification';
                    var healClassificationQualifier = $('#'+healClassificationField+'_qualifier');

                    var healClassificationAC = $('#'+healClassificationField+'_value').autocomplete({
						source: "</xsl:text><xsl:value-of select="concat($context-path,'/JSON/rdf/search/keywords')"/><xsl:text>",
						minLength: 3,
						open: function() {
					        $('#'+healClassificationField+'_value').autocomplete("widget").width(600)
					    }
					});

					healClassificationQualifier.change(function() {
						var qualifier = $(this).val();
						var acSource = '</xsl:text><xsl:value-of select="concat($context-path,'/JSON/rdf/search/keywords')"/><xsl:text>' + '?vocab=' + qualifier;
						healClassificationAC.autocomplete("option","source",acSource);
						//console.log(healClassificationAC.autocomplete("option", "source"));
					});

                    healClassificationQualifier.find('option:first').attr("selected", true).trigger('change');

				});</xsl:text>
            </script>
        </xsl:if>
        <!-- END aanagnostopoulos -->

    </xsl:template>

</xsl:stylesheet>
