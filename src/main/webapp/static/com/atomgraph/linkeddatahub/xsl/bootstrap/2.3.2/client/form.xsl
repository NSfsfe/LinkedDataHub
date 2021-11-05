<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY apl    "https://w3id.org/atomgraph/linkeddatahub/domain#">
    <!ENTITY dydra  "https://w3id.org/atomgraph/linkeddatahub/services/dydra#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY srx    "http://www.w3.org/2005/sparql-results#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy/domain#">
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY dct    "http://purl.org/dc/terms/">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
    <!ENTITY nfo    "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#">
]>
<xsl:stylesheet version="3.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:prop="http://saxonica.com/ns/html-property"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:json="http://www.w3.org/2005/xpath-functions"
xmlns:array="http://www.w3.org/2005/xpath-functions/array"
xmlns:ac="&ac;"
xmlns:apl="&apl;"
xmlns:rdf="&rdf;"
xmlns:srx="&srx;"
xmlns:ldt="&ldt;"
xmlns:sd="&sd;"
xmlns:foaf="&foaf;"
xmlns:sp="&sp;"
xmlns:nfo="&nfo;"
xmlns:dydra="&dydra;"
xmlns:dydra-urn="urn:dydra:"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>

    <!-- TEMPLATES -->

    <!-- currently unused -->
    <xsl:template name="add-value-listeners">
        <xsl:param name="id" as="xs:string"/>
        
        <xsl:for-each select="id($id, ixsl:page())">
            <xsl:apply-templates select="." mode="apl:PostConstructMode"/>
            
            <xsl:value-of select="ixsl:call(., 'focus', [])"/>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="add-form-listeners">
        <xsl:param name="form" as="element()"/>
        <xsl:message>FORM ID: <xsl:value-of select="$form/@id"/></xsl:message>

        <xsl:apply-templates select="$form" mode="apl:PostConstructMode"/>
    </xsl:template>

    <xsl:template match="*" mode="apl:PostConstructMode">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
    <!-- listener identity transform - binding event listeners to inputs -->
    
    <xsl:template match="text()" mode="apl:PostConstructMode"/>

    <!-- subject type change -->
    <xsl:template match="select[tokenize(@class, ' ') = 'subject-type']" mode="apl:PostConstructMode" priority="1">
        <xsl:message>
            <xsl:value-of select="ixsl:call(., 'addEventListener', [ 'change', ixsl:get(ixsl:window(), 'onSubjectTypeChange') ])"/>
        </xsl:message>
    </xsl:template>
    
    <xsl:template match="textarea[tokenize(@class, ' ') = 'wymeditor']" mode="apl:PostConstructMode" priority="1">
        <!-- without wrapping into comment, we get: SEVERE: In delayed event: DOM error appending text node with value: '[object Object]' to node with name: #document -->
        <xsl:message>
            <!-- call .wymeditor() on textarea to show WYMEditor -->
            <xsl:sequence select="ixsl:call(ixsl:call(ixsl:window(), 'jQuery', [ . ]), 'wymeditor', [])"/>
        </xsl:message>
    </xsl:template>

    <!-- TO-DO: phase out as regular ixsl: event templates -->
    <xsl:template match="fieldset//input" mode="apl:PostConstructMode" priority="1">
        <!-- subject value change -->
        <xsl:if test="tokenize(@class, ' ') = 'subject'">
            <xsl:message>
                <xsl:value-of select="ixsl:call(., 'addEventListener', [ 'change', ixsl:get(ixsl:window(), 'onSubjectValueChange') ])"/>
            </xsl:message>
        </xsl:if>
        <!-- typeahead blur -->
        <xsl:if test="tokenize(@class, ' ') = 'resource-typeahead'">
            <xsl:message>
                <xsl:value-of select="ixsl:call(., 'addEventListener', [ 'blur', ixsl:get(ixsl:window(), 'onTypeaheadInputBlur') ])"/>
            </xsl:message>
        </xsl:if>
        <!-- prepended/appended input -->
        <xsl:if test="@type = 'text' and ../tokenize(@class, ' ') = ('input-prepend', 'input-append')">
            <xsl:variable name="value" select="concat(preceding-sibling::*[@class = 'add-on']/text(), @value, following-sibling::*[@class = 'add-on']/text())" as="xs:string?"/>
            <xsl:message>Concatenated @value: <xsl:value-of select="$value"/></xsl:message>
            <!-- set the initial value the same way as the event handler does -->
            <ixsl:set-property object="../input[@type = 'hidden']" name="value" select="$value"/>

            <xsl:message>
                <xsl:value-of select="ixsl:call(., 'addEventListener', [ 'change', ixsl:get(ixsl:window(), 'onPrependedAppendedInputChange') ])"/>
            </xsl:message>
        </xsl:if>
        
        <!-- TO-DO: move to a better place. Does not take effect if typeahead is reset -->
        <ixsl:set-property object="." name="autocomplete" select="'off'"/>
    </xsl:template>
    
    <!-- form identity transform -->
    
    <xsl:template match="@for | @id" mode="form" priority="1">
        <xsl:param name="doc-id" as="xs:string" tunnel="yes"/>
        
        <xsl:attribute name="{name()}" select="concat($doc-id, .)"/>
    </xsl:template>
    
    <xsl:template match="input[@class = 'target-id']" mode="form" priority="1">
        <xsl:param name="target-id" as="xs:string?" tunnel="yes"/>
        
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:if test="$target-id">
                <xsl:attribute name="value" select="$target-id"/>
            </xsl:if>
        </xsl:copy>
    </xsl:template>

    <!-- regenerates slug literal UUID because form (X)HTML can be cached -->
    <xsl:template match="input[@name = 'ol'][ancestor::div[@class = 'controls']/preceding-sibling::input[@name = 'pu']/@value = '&dh;slug']" mode="form" priority="1">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:attribute name="value" select="ixsl:call(ixsl:window(), 'generateUUID', [])"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="@* | node()" mode="form">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- EVENT HANDLERS -->
    
    <xsl:template match="form[tokenize(@class, ' ') = 'form-horizontal'] | form[ancestor::div[tokenize(@class, ' ') = 'modal']]" mode="ixsl:onsubmit">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:variable name="form" select="." as="element()"/>
        <xsl:variable name="id" select="ixsl:get(., 'id')" as="xs:string"/>
        <xsl:variable name="method" select="ixsl:get(., 'method')" as="xs:string"/>
        <xsl:variable name="action" select="ixsl:get(., 'action')" as="xs:anyURI"/>
        <xsl:variable name="enctype" select="ixsl:get(., 'enctype')" as="xs:string"/>
        <xsl:variable name="accept" select="'application/xhtml+xml'" as="xs:string"/>

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>
        
        <!-- remove names of RDF/POST inputs with empty values -->
        <xsl:for-each select=".//input[@name = ('ob', 'ou', 'ol')][not(ixsl:get(., 'value'))]">
            <ixsl:remove-attribute name="name"/>
        </xsl:for-each>
        
        <!-- TO-DO: override $action with the sioc:has_container/sioc:has_parent typeahead value? -->

        <xsl:choose>
            <!-- we need to handle multipart requests specially because of Saxon-JS 2 limitations: https://saxonica.plan.io/issues/4732 -->
            <xsl:when test="$enctype = 'multipart/form-data'">
                <xsl:variable name="js-statement" as="element()">
                    <root statement="new FormData(document.getElementById('{$id}'))"/>
                </xsl:variable>
                <xsl:variable name="form-data" select="ixsl:eval(string($js-statement/@statement))"/>
                <xsl:variable name="js-statement" as="element()">
                    <root statement="{{ 'Accept': '{$accept}' }}"/>
                </xsl:variable>
                <xsl:variable name="headers" select="ixsl:eval(string($js-statement/@statement))"/>
                
                <xsl:sequence select="js:fetchDispatchXML($action, $method, $headers, $form-data, ., 'multipartFormLoad')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="js-statement" as="element()">
                    <root statement="new URLSearchParams(new FormData(document.getElementById('{$id}')))"/>
                </xsl:variable>
                <xsl:variable name="form-data" select="ixsl:eval(string($js-statement/@statement))"/>

                <xsl:variable name="request" as="item()*">
                    <ixsl:schedule-action http-request="map{ 'method': $method, 'href': $action, 'media-type': $enctype, 'body': $form-data, 'headers': map{ 'Accept': $accept } }">
                        <xsl:call-template name="onFormLoad">
                            <xsl:with-param name="action" select="$action"/>
                            <xsl:with-param name="form" select="$form"/>
                            <xsl:with-param name="target-id" select="$form/input[@class = 'target-id']/@value"/>
                        </xsl:call-template>
                    </ixsl:schedule-action>
                </xsl:variable>
                <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="button[tokenize(@class, ' ') = 'add-value']" mode="ixsl:onclick">
        <xsl:variable name="control-group" select="../.." as="element()"/> <!-- ../../copy-of() -->
        <xsl:variable name="property" select="../preceding-sibling::*/select/option[ixsl:get(., 'selected') = true()]/ixsl:get(., 'value')" as="xs:anyURI"/>
        <xsl:variable name="forClass" select="preceding-sibling::input/@value" as="xs:anyURI*"/>
        <xsl:variable name="href" select="ac:build-uri(apl:absolute-path(), map{ 'forClass': string($forClass) })" as="xs:anyURI"/>
        <xsl:message>Form URI: <xsl:value-of select="$href"/></xsl:message>
        
        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>
        
        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $href, 'headers': map{ 'Accept': 'application/xhtml+xml' } }">
                <xsl:call-template name="onAddValueCallback">
                    <xsl:with-param name="forClass" select="$forClass"/>
                    <xsl:with-param name="control-group" select="$control-group"/>
                    <xsl:with-param name="property" select="$property"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>
        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>

    <xsl:template match="button[tokenize(@class, ' ') = 'add-constructor']" mode="ixsl:onclick">
        <xsl:variable name="uri" select="apl:absolute-path()" as="xs:anyURI"/>
        <xsl:variable name="forClass" select="input[@class = 'forClass']/@value" as="xs:anyURI"/>
        <!--- show a modal form if this button is in a <fieldset>, meaning on a resource-level and not form level. Otherwise (e.g. for the "Create" button) show normal form -->
        <xsl:variable name="modal-form" select="exists(ancestor::fieldset)" as="xs:boolean"/>
        <xsl:variable name="href" select="ac:build-uri($uri, let $params := map{ 'forClass': string($forClass) } return if ($modal-form) then map:merge(($params, map{ 'mode': '&ac;ModalMode' })) else $params)" as="xs:anyURI"/>
        <xsl:message>Form URI: <xsl:value-of select="$href"/></xsl:message>

        <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>
        
        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $href, 'headers': map{ 'Accept': 'application/xhtml+xml' } }">
                <xsl:call-template name="onAddForm"/>
            </ixsl:schedule-action>
        </xsl:variable>
        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>
    
    <!-- toggle between Content as URI resource and HTML (rdf:XMLLiteral) -->
    <xsl:template match="select[tokenize(@class, ' ') = 'content-type']" mode="ixsl:onchange">
        <xsl:variable name="content-type" select="ixsl:get(., 'value')" as="xs:anyURI"/>
        <xsl:variable name="controls" select=".." as="element()"/>

        <xsl:if test="$content-type = '&rdfs;Resource'">
            <xsl:variable name="constructor" as="document-node()">
                <xsl:document>
                    <rdf:RDF>
                        <rdf:Description rdf:nodeID="A1">
                            <rdf:first rdf:nodeID="A2"/>
                        </rdf:Description>
                        <rdf:Description rdf:nodeID="A2">
                            <rdf:type rdf:resource="&rdfs;Resource"/>
                        </rdf:Description>
                    </rdf:RDF>
                </xsl:document>
            </xsl:variable>
            <xsl:variable name="new-controls" as="node()*">
                <xsl:apply-templates select="$constructor//rdf:first/@rdf:*" mode="bs2:FormControl"/>
            </xsl:variable>
            
            <xsl:for-each select="$controls">
                <xsl:result-document href="?." method="ixsl:replace-content">
                    <!-- don't insert a new <div class="controls">, only its children -->
                    <xsl:copy-of select="$new-controls"/>
                </xsl:result-document>
            </xsl:for-each>
        </xsl:if>
        <xsl:if test="$content-type = '&rdf;XMLLiteral'">
            <xsl:variable name="constructor" as="document-node()">
                <xsl:document>
                    <rdf:RDF>
                        <rdf:Description rdf:nodeID="A1">
                            <rdf:first rdf:parseType="Literal">
                                <xhtml:div/>
                            </rdf:first>
                        </rdf:Description>
                    </rdf:RDF>
                </xsl:document>
            </xsl:variable>
            <xsl:variable name="new-controls" as="node()*">
                <xsl:apply-templates select="$constructor//rdf:first/xhtml:*" mode="bs2:FormControl"/>
            </xsl:variable>

            <xsl:for-each select="$controls">
                <xsl:result-document href="?." method="ixsl:replace-content">
                    <!-- don't insert a new <div class="controls">, only its children -->
                    <xsl:copy-of select="$new-controls"/>
                </xsl:result-document>
                
                <!-- key() lookup doesn't work because of https://saxonica.plan.io/issues/5036 -->
                <!--<xsl:apply-templates select="key('elements-by-class', 'wymeditor', .)" mode="apl:PostConstructMode"/>-->
                <!-- initialize wymeditor textarea -->
                <xsl:apply-templates select="descendant::*[tokenize(@class, ' ') = 'wymeditor']" mode="apl:PostConstructMode"/>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    

    <!-- remove <fieldset> (button is within <legend>) -->
    <xsl:template match="fieldset/legend/div/button[tokenize(@class, ' ') = 'btn-remove-resource']" mode="ixsl:onclick" priority="1">
        <xsl:message>
            <xsl:value-of select="ixsl:call(../../.., 'remove', [])"/>
        </xsl:message>
    </xsl:template>

    <!-- remove <fieldset> (button is within <fieldset>) -->
    <xsl:template match="fieldset/div/button[tokenize(@class, ' ') = 'btn-remove-resource']" mode="ixsl:onclick" priority="1">
        <xsl:message>
            <xsl:value-of select="ixsl:call(../.., 'remove', [])"/>
        </xsl:message>
    </xsl:template>

    <!-- remove <div class="control-group"> -->
    <xsl:template match="button[tokenize(@class, ' ') = 'btn-remove-property']" mode="ixsl:onclick" priority="1">
        <xsl:message>
            <xsl:value-of select="ixsl:call(../../.., 'remove', [])"/>
        </xsl:message>
    </xsl:template>

    <xsl:template match="button[tokenize(@class, ' ') = 'add-type']" mode="ixsl:onclick" priority="1">
        <xsl:param name="lookup-class" select="'type-typeahead typeahead'" as="xs:string"/>
        <xsl:param name="lookup-list-class" select="'type-typeahead typeahead dropdown-menu'" as="xs:string"/>
        <xsl:variable name="uuid" select="ixsl:call(ixsl:window(), 'generateUUID', [])" as="xs:string"/>
        
        <xsl:for-each select="..">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:call-template name="bs2:Lookup">
                    <xsl:with-param name="class" select="$lookup-class"/>
                    <xsl:with-param name="id" select="concat('input-', $uuid)"/>
                    <xsl:with-param name="list-class" select="$lookup-list-class"/>
                </xsl:call-template>
            </xsl:result-document>
        </xsl:for-each>
        <xsl:for-each select="../..">
            <xsl:result-document href="?." method="ixsl:append-content">
                <xsl:copy-of select=".."/>
            </xsl:result-document>
        </xsl:for-each>

        <xsl:call-template name="add-typeahead">
            <xsl:with-param name="id" select="concat('input-', $uuid)"/>
        </xsl:call-template>
    </xsl:template>

    <!-- special case for rdf:type lookups -->
    <xsl:template match="button[tokenize(@class, ' ') = 'add-typetypeahead']" mode="ixsl:onclick" priority="1">
        <xsl:next-match>
            <xsl:with-param name="lookup-class" select="'type-typeahead typeahead'"/>
            <xsl:with-param name="lookup-list-class" select="'type-typeahead typeahead dropdown-menu'" as="xs:string"/>
        </xsl:next-match>
    </xsl:template>
    
    <xsl:template match="button[tokenize(@class, ' ') = 'add-typeahead']" mode="ixsl:onclick">
        <xsl:param name="lookup-class" select="'resource-typeahead typeahead'" as="xs:string"/>
        <xsl:param name="lookup-list-class" select="'resource-typeahead typeahead dropdown-menu'" as="xs:string"/>
        <xsl:variable name="uuid" select="ixsl:call(ixsl:window(), 'generateUUID', [])" as="xs:string"/>
        
        <xsl:for-each select="..">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:call-template name="bs2:Lookup">
                    <xsl:with-param name="class" select="$lookup-class"/>
                    <xsl:with-param name="id" select="concat('input-', $uuid)"/>
                    <xsl:with-param name="list-class" select="$lookup-list-class"/>
                </xsl:call-template>
            </xsl:result-document>
        </xsl:for-each>

        <xsl:call-template name="add-typeahead">
            <xsl:with-param name="id" select="concat('input-', $uuid)"/>
        </xsl:call-template>
    </xsl:template>
    
    <!-- simplified version of Bootstrap's tooltip() -->
    
    <xsl:template match="fieldset//input" mode="ixsl:onmouseover">
        <xsl:choose>
            <!-- show existing tooltip -->
            <xsl:when test="../div[tokenize(@class, ' ') = 'tooltip']">
                <ixsl:set-style name="display" select="'block'" object="../div[tokenize(@class, ' ') = 'tooltip']"/>
            </xsl:when>
            <!-- append new tooltip -->
            <xsl:otherwise>
                <xsl:variable name="description-span" select="ancestor::*[tokenize(@class, ' ') = 'control-group']//*[tokenize(@class, ' ') = 'description']" as="element()?"/>
                <xsl:if test="$description-span">
                    <xsl:variable name="input-offset-width" select="ixsl:get(., 'offsetWidth')" as="xs:integer"/>
                    <xsl:variable name="input-offset-height" select="ixsl:get(., 'offsetHeight')" as="xs:integer"/>
                    <xsl:for-each select="..">
                        <xsl:result-document href="?." method="ixsl:append-content">
                            <div class="tooltip fade top in">
                                <div class="tooltip-arrow"></div>
                                <div class="tooltip-inner">
                                    <xsl:sequence select="$description-span/text()"/>
                                </div>
                            </div>
                        </xsl:result-document>
                    </xsl:for-each>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
        <!-- adjust the position of the tooltip relative to the input -->
        <xsl:variable name="input-top" select="ixsl:get(., 'offsetTop')" as="xs:double"/>
        <xsl:variable name="input-left" select="ixsl:get(., 'offsetLeft')" as="xs:double"/>
        <xsl:variable name="input-width" select="ixsl:get(., 'offsetWidth')" as="xs:double"/>
        <xsl:for-each select="../div[tokenize(@class, ' ') = 'tooltip']">
            <xsl:variable name="tooltip-height" select="ixsl:get(., 'offsetHeight')" as="xs:double"/>
            <xsl:variable name="tooltip-width" select="ixsl:get(., 'offsetWidth')" as="xs:double"/>
            
            <ixsl:set-style name="top" select="($input-top - $tooltip-height) || 'px'"/>
            <ixsl:set-style name="left" select="($input-left + ($input-width - $tooltip-width) div 2) || 'px'"/>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="fieldset//input" mode="ixsl:onmouseout">
        <xsl:for-each select="../div[tokenize(@class, ' ') = 'tooltip']">
            <ixsl:set-style name="display" select="'none'"/>
        </xsl:for-each>
    </xsl:template>
    
    <!-- close modal form -->
    
    <xsl:template match="div[tokenize(@class, ' ') = 'modal']//button[tokenize(@class, ' ') = ('close', 'btn-close')]" mode="ixsl:onclick">
        <xsl:for-each select="ancestor::div[tokenize(@class, ' ') = 'modal']">
            <xsl:message>
                <xsl:value-of select="ixsl:call(., 'remove', [])"/>
            </xsl:message>
        </xsl:for-each>
    </xsl:template>
    
    <!-- CALLBACKS -->
    
    <!-- the same logic as onFormLoad but handles only responses to multipart requests invoked via JS function fetchDispatchXML() -->
    <xsl:template match="." mode="ixsl:onmultipartFormLoad">
        <xsl:param name="container" select="id('content-body', ixsl:page())" as="element()"/>
        <xsl:variable name="event" select="ixsl:event()"/>
        <xsl:variable name="action" select="ixsl:get(ixsl:get($event, 'detail'), 'action')" as="xs:anyURI"/>
        <xsl:variable name="form" select="ixsl:get(ixsl:get($event, 'detail'), 'target')" as="element()"/> <!-- not ixsl:get(ixsl:event(), 'target') because that's the whole document -->
        <xsl:variable name="target-id" select="$form/input[@class = 'target-id']/@value" as="xs:string?"/>
        <!-- $target-id is of the "Create" button, need to replace the preceding typeahead input instead -->
        <xsl:variable name="typeahead-span" select="if ($target-id) then id($target-id, ixsl:page())/ancestor::div[@class = 'controls']//span[descendant::input[@name = 'ou']] else ()" as="element()?"/>
        <xsl:variable name="response" select="ixsl:get(ixsl:get($event, 'detail'), 'response')"/>
        <xsl:variable name="html" select="if (ixsl:contains($event, 'detail.xml')) then ixsl:get($event, 'detail.xml') else ()" as="document-node()?"/>

        <xsl:variable name="response" as="map(*)">
            <xsl:map>
                <xsl:map-entry key="'body'" select="$html"/>
                <xsl:map-entry key="'status'" select="ixsl:get($response, 'status')"/>
                <xsl:map-entry key="'media-type'" select="ixsl:call(ixsl:get($response, 'headers'), 'get', [ 'Content-Type' ])"/>
                <xsl:map-entry key="'headers'">
                    <xsl:map>
                        <xsl:map-entry key="'location'" select="ixsl:call(ixsl:get($response, 'headers'), 'get', [ 'Location' ])"/>
                        <!-- TO-DO: create a map of all headers from response.headers -->
                    </xsl:map>
                </xsl:map-entry>
            </xsl:map>
        </xsl:variable>
        
        <xsl:for-each select="$response">
            <xsl:call-template name="onFormLoad">
                <xsl:with-param name="container" select="$container"/>
                <xsl:with-param name="action" select="$action"/>
                <xsl:with-param name="form" select="$form"/>
                <xsl:with-param name="target-id" select="$target-id"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>
    
    <!-- after "Create" or "Edit" buttons are clicked" -->
    <xsl:template name="onAddForm">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container" select="id('content-body', ixsl:page())" as="element()"/>
        <xsl:param name="add-class" as="xs:string?"/>
        <xsl:param name="target-id" as="xs:string?"/>
        <xsl:param name="new-form-id" as="xs:string?"/>
        <xsl:param name="new-target-id" as="xs:string?"/>

        <xsl:choose>
            <xsl:when test="?status = 200 and starts-with(?media-type, 'application/xhtml+xml')">
                <xsl:for-each select="?body">
                    <xsl:variable name="event" select="ixsl:event()"/>
                    <xsl:variable name="target" select="ixsl:get($event, 'target')"/>
                    <xsl:variable name="modal" select="exists(//div[tokenize(@class, ' ') = 'modal-constructor'])" as="xs:boolean"/>
                    <xsl:variable name="target-id" select="$target/@id" as="xs:string?"/>
                    <xsl:variable name="doc-id" select="concat('id', ixsl:call(ixsl:window(), 'generateUUID', []))" as="xs:string"/>
                    
                    <xsl:choose>
                        <xsl:when test="$modal">
                            <xsl:variable name="modal-div" as="element()">
                                <xsl:apply-templates select="//div[tokenize(@class, ' ') = 'modal-constructor']" mode="form">
                                    <xsl:with-param name="target-id" select="$target-id" tunnel="yes"/>
                                    <xsl:with-param name="doc-id" select="$doc-id" tunnel="yes"/>
                                </xsl:apply-templates>
                            </xsl:variable>
                            <xsl:variable name="form-id" select="$modal-div//form/@id" as="xs:string"/>
                            
                            <xsl:if test="$add-class">
                                <xsl:sequence select="$modal-div//form/ixsl:call(ixsl:get(., 'classList'), 'toggle', [ $add-class, true() ])[current-date() lt xs:date('2000-01-01')]"/>
                            </xsl:if>

                            <xsl:for-each select="ixsl:page()//body">
                                <xsl:result-document href="?." method="ixsl:append-content">
                                    <!-- append modal div to body -->
                                    <xsl:copy-of select="$modal-div"/>
                                </xsl:result-document>
                            </xsl:for-each>
                            
                            <!-- add event listeners to the descendants of the form. TO-DO: replace with XSLT -->
                            <xsl:if test="id($form-id, ixsl:page())">
                                <xsl:call-template name="add-form-listeners">
                                    <xsl:with-param name="form" select="id($form-id, ixsl:page())"/>
                                </xsl:call-template>
                            </xsl:if>
                            
                            <xsl:if test="$new-target-id">
                                <!-- overwrite target-id input's value with the provided value -->
                                <xsl:for-each select="id($form-id, ixsl:page())//input[@class = 'target-id']"> <!-- why @class and not @name?? -->
                                    <ixsl:set-property name="value" select="$new-target-id" object="."/>
                                </xsl:for-each>
                            </xsl:if>
                            <xsl:if test="$new-form-id">
                                <!-- overwrite form @id with the provided value -->
                                <ixsl:set-property name="id" select="$new-form-id" object="id($form-id, ixsl:page())"/>
                            </xsl:if>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:variable name="form" as="element()">
                                <xsl:apply-templates select="//form" mode="form">
                                    <xsl:with-param name="target-id" select="$target-id" tunnel="yes"/>
                                    <xsl:with-param name="doc-id" select="$doc-id" tunnel="yes"/>
                                </xsl:apply-templates>
                            </xsl:variable>
                            <xsl:variable name="form-id" select="$form/@id" as="xs:string"/>
                            
                            <xsl:if test="$add-class">
                                <xsl:sequence select="$form/ixsl:call(ixsl:get(., 'classList'), 'toggle', [ $add-class, true() ])[current-date() lt xs:date('2000-01-01')]"/>
                            </xsl:if>
                            
                            <xsl:choose>
                                <!-- if "Create" button is within the <form>, append elements to <form> -->
                                <xsl:when test="$target/ancestor::form[tokenize(@class, ' ') = 'form-horizontal']">
                                    <xsl:for-each select="$target/ancestor::form[tokenize(@class, ' ') = 'form-horizontal']">
                                        <!-- remove the old form-actions <div> because we'll be appending a new one below -->
                                        <xsl:for-each select="div[tokenize(@class, ' ') = 'form-actions']">
                                            <xsl:message>
                                                <xsl:value-of select="ixsl:call(., 'remove', [])"/>
                                            </xsl:message>
                                        </xsl:for-each>
                                        <!-- remove this "Create" button -->
                                        <xsl:for-each select="$target/ancestor::div[tokenize(@class, ' ') = 'btn-group'][button[tokenize(@class, ' ') = 'create-action']]">
                                            <xsl:message>
                                                <xsl:value-of select="ixsl:call(., 'remove', [])"/>
                                            </xsl:message>
                                        </xsl:for-each>

                                        <xsl:result-document href="?." method="ixsl:append-content">
                                            <xsl:copy-of select="$form/*"/>
                                        </xsl:result-document>
                                    </xsl:for-each>
                                </xsl:when>
                                <!-- there's no <form> so we're not in EditMode - replace the whole content -->
                                <xsl:otherwise>
                                    <xsl:for-each select="$container">
                                        <xsl:result-document href="?." method="ixsl:replace-content">
                                            <!-- TO-DO: move to server-side as a separate template that extends bs2:Form? -->
                                            <div class="row-fluid">
                                                <div class="left-nav span2"></div>

                                                <div class="span7">
                                                    <xsl:copy-of select="$form"/>
                                                </div>
                                            </div>
                                        </xsl:result-document>
                                    </xsl:for-each>
                                </xsl:otherwise>
                            </xsl:choose>
                            
                            <!-- add event listeners to the descendants of the form. TO-DO: replace with XSLT -->
                            <xsl:if test="id($form-id, ixsl:page())">
                                <xsl:call-template name="add-form-listeners">
                                    <xsl:with-param name="form" select="id($form-id, ixsl:page())"/>
                                </xsl:call-template>
                            </xsl:if>
                    
                            <xsl:if test="$new-target-id">
                                <!-- overwrite target-id input's value with the provided value -->
                                <xsl:for-each select="id($form-id, ixsl:page())//input[@class = 'target-id']"> <!-- why @class and not @name?? -->
                                    <ixsl:set-property name="value" select="$new-target-id" object="."/>
                                </xsl:for-each>
                            </xsl:if>
                            <xsl:if test="$new-form-id">
                                <!-- overwrite form's @id with the provided value -->
                                <ixsl:set-property name="id" select="$new-form-id" object="id($form-id, ixsl:page())"/>
                            </xsl:if>
                        </xsl:otherwise>
                    </xsl:choose>

                    <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="ixsl:call(ixsl:window(), 'alert', [ ?message ])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="onAddValueCallback">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="forClass" as="xs:anyURI"/>
        <xsl:param name="control-group" as="element()"/>
        <xsl:param name="property" as="xs:anyURI"/>
        
        <xsl:choose>
            <xsl:when test="?status = 200 and starts-with(?media-type, 'application/xhtml+xml')">
                <xsl:for-each select="?body">
                    <xsl:variable name="doc-id" select="'id' || ixsl:call(ixsl:window(), 'generateUUID', [])" as="xs:string"/>
                    <xsl:variable name="form" as="element()">
                        <xsl:apply-templates select="//form[@class = 'form-horizontal']" mode="form">
                            <xsl:with-param name="doc-id" select="$doc-id" tunnel="yes"/>
                        </xsl:apply-templates>
                    </xsl:variable>
                    <xsl:variable name="new-control-group" select="$form//div[tokenize(@class, ' ') = 'control-group'][input[@name = 'pu']/@value = $property]" as="element()"/>
                    
                    <xsl:for-each select="$control-group">
                        <!-- move property creation control group down, by appending it to the parent fieldset -->
                        <xsl:for-each select="$control-group/..">
                            <xsl:result-document href="?." method="ixsl:append-content">
                                <xsl:copy-of select="$control-group"/>
                            </xsl:result-document>
                        </xsl:for-each>

                        <xsl:result-document href="?." method="ixsl:replace-content">
                            <xsl:copy-of select="$new-control-group/*"/>
                        </xsl:result-document>
                        
                        <!-- apply WYMEditor on textarea if object is XMLLiteral -->
<!--                        <xsl:call-template name="add-value-listeners">
                            <xsl:with-param name="id" select="$new-control-group//input[@name = ('ob', 'ou', 'ol')]/@id"/>
                        </xsl:call-template>-->
                        
                        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
                    </xsl:for-each>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="ixsl:call(ixsl:window(), 'alert', [ ?message ])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- after form is submitted. TO-DO: split into multiple callbacks and avoid <xsl:choose>? -->
    <xsl:template name="onFormLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="container" select="id('content-body', ixsl:page())" as="element()"/>
        <xsl:param name="action" as="xs:anyURI"/>
        <xsl:param name="form" as="element()"/>
        <xsl:param name="target-id" as="xs:string?"/>
        <!-- $target-id is of the "Create" button, need to replace the preceding typeahead input instead -->
        <xsl:param name="typeahead-span" select="if ($target-id) then id($target-id, ixsl:page())/ancestor::div[@class = 'controls']//span[descendant::input[@name = 'ou']] else ()" as="element()?"/>

        <xsl:message>
            Form loaded with ?status: <xsl:value-of select="?status"/> ?media-type: <xsl:value-of select="?media-type"/> $target-id: <xsl:value-of select="$target-id"/> exists($typeahead-span): <xsl:value-of select="exists($typeahead-span)"/>
        </xsl:message>
        
        <xsl:choose>
            <!-- special case for add/clone data forms: redirect to the container -->
            <xsl:when test="ixsl:get($form, 'id') = ('form-add-data', 'form-clone-data')">
                <xsl:variable name="control-group" select="$form/descendant::div[tokenize(@class, ' ') = 'control-group'][input[@name = 'pu'][@value = '&sd;name']]" as="element()*"/>
                <xsl:variable name="uri" select="$control-group/descendant::input[@name = 'ou']/ixsl:get(., 'value')" as="xs:anyURI"/>
                
                <!-- load document -->
                <xsl:variable name="request" as="item()*">
                    <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $uri, 'headers': map{ 'Accept': 'application/xhtml+xml' } }">
                        <xsl:call-template name="onDocumentLoad">
                            <xsl:with-param name="uri" select="ac:document-uri($uri)"/>
                            <xsl:with-param name="fragment" select="encode-for-uri($uri)"/>
                        </xsl:call-template>
                    </ixsl:schedule-action>
                </xsl:variable>
                <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
                
                <!-- remove the modal div -->
                <xsl:sequence select="ixsl:call($form/ancestor::div[tokenize(@class, ' ') = 'modal'], 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:when>
            <!-- special case for "Save query/chart" forms: simpy hide the modal form -->
            <xsl:when test="tokenize($form/@class, ' ') = ('form-save-query', 'form-save-chart')">
                <!-- remove the modal div -->
                <xsl:sequence select="ixsl:call($form/ancestor::div[tokenize(@class, ' ') = 'modal'], 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
            </xsl:when>
            <xsl:when test="?status = 200">
                <xsl:choose>
                    <xsl:when test="starts-with(?media-type, 'application/xhtml+xml')"> <!-- allow 'application/xhtml+xml;charset=UTF-8' as well -->
                        <xsl:apply-templates select="?body" mode="apl:Document">
                            <xsl:with-param name="container" select="$container"/>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- trim the query string if it's present --> 
                        <xsl:variable name="uri" select="if (contains($action, '?')) then xs:anyURI(substring-before($action, '?')) else $action" as="xs:anyURI"/>
                        
                        <!--reload resource--> 
                        <xsl:variable name="request" as="item()*">
                            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $uri, 'headers': map{ 'Accept': 'application/xhtml+xml' } }">
                                <xsl:call-template name="onDocumentLoad">
                                    <xsl:with-param name="uri" select="ac:document-uri($uri)"/>
                                    <xsl:with-param name="fragment" select="encode-for-uri($uri)"/>
                                </xsl:call-template>
                            </ixsl:schedule-action>
                        </xsl:variable>
                        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- POST created new resource successfully -->
            <xsl:when test="?status = 201 and ?headers?location">
                <xsl:variable name="created-uri" select="?headers?location" as="xs:anyURI"/>
                <xsl:choose>
                    <!-- render the created resource as a typeahead input -->
                    <xsl:when test="$typeahead-span">
                        <xsl:variable name="request" as="item()*">
                            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $created-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                                <xsl:call-template name="onTypeaheadResourceLoad">
                                    <xsl:with-param name="resource-uri" select="$created-uri"/>
                                    <xsl:with-param name="typeahead-span" select="$typeahead-span"/>
                                    <xsl:with-param name="modal-form" select="$form"/>
                                </xsl:call-template>
                            </ixsl:schedule-action>
                        </xsl:variable>
                        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
                    </xsl:when>
                    <!-- if the form submit did not originate from a typeahead (target), load the created resource -->
                    <xsl:otherwise>
                        <xsl:variable name="request" as="item()*">
                            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $created-uri, 'headers': map{ 'Accept': 'application/xhtml+xml' } }">
                                <xsl:call-template name="onDocumentLoad">
                                    <xsl:with-param name="uri" select="ac:document-uri($created-uri)"/>
                                    <xsl:with-param name="fragment" select="encode-for-uri($created-uri)"/>
                                </xsl:call-template>
                            </ixsl:schedule-action>
                        </xsl:variable>
                        
                        <!-- store the new request object -->
                        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- POST or PUT constraint violation response is 400 Bad Request -->
            <xsl:when test="?status = 400 and starts-with(?media-type, 'application/xhtml+xml')"> <!-- allow 'application/xhtml+xml;charset=UTF-8' as well -->
                <xsl:for-each select="?body">
                    <xsl:variable name="form-id" select="ixsl:get($form, 'id')" as="xs:string"/>
                    <xsl:variable name="doc-id" select="concat('id', ixsl:call(ixsl:window(), 'generateUUID', []))" as="xs:string"/>
                    <xsl:variable name="form" as="element()">
                        <xsl:apply-templates select="//form[@class = 'form-horizontal']" mode="form">
                            <xsl:with-param name="target-id" select="$target-id" tunnel="yes"/>
                            <xsl:with-param name="doc-id" select="$doc-id" tunnel="yes"/>
                        </xsl:apply-templates>
                    </xsl:variable>
                    
                    <xsl:result-document href="#{$form-id}" method="ixsl:replace-content">
                        <xsl:copy-of select="$form/*"/>
                    </xsl:result-document>

                    <xsl:call-template name="add-form-listeners">
                        <xsl:with-param name="form" select="id($form-id, ixsl:page())"/>
                    </xsl:call-template>
                    
                    <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
                <xsl:value-of select="ixsl:call(ixsl:window(), 'alert', [ ?message ])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>