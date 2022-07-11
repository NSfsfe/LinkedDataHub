// Copyright 2021 Martynas Jusevičius <martynas@atomgraph.com>
// SPDX-FileCopyrightText: 2017-2022 2017 Martynas Jusevicius, <martynas@atomgraph.com> et al.
//
// SPDX-License-Identifier: Apache-2.0

package com.atomgraph.linkeddatahub.server.filter.response;

import com.atomgraph.client.vocabulary.AC;
import com.atomgraph.client.vocabulary.LDT;
import com.atomgraph.core.util.Link;
import com.atomgraph.core.vocabulary.SD;
import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.apps.model.Dataset;
import com.atomgraph.linkeddatahub.model.Agent;
import com.atomgraph.linkeddatahub.server.filter.request.AuthorizationFilter;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import javax.annotation.Priority;
import javax.inject.Inject;
import javax.ws.rs.Priorities;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.container.ContainerResponseContext;
import javax.ws.rs.container.ContainerResponseFilter;
import javax.ws.rs.core.HttpHeaders;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Property;
import org.apache.jena.rdf.model.RDFNode;
import org.apache.jena.rdf.model.ResIterator;
import org.apache.jena.rdf.model.Resource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Response filter that sets <code>Link</code> response headers with hypermedia links.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
@Priority(Priorities.USER + 300)
public class ResponseHeaderFilter implements ContainerResponseFilter
{

    private static final Logger log = LoggerFactory.getLogger(ResponseHeaderFilter.class);

    @Inject javax.inject.Provider<Application> app;
    @Inject javax.inject.Provider<Optional<Dataset>> dataset;

    @Override
    public void filter(ContainerRequestContext request, ContainerResponseContext response)throws IOException
    {
        if (request.getSecurityContext().getUserPrincipal() instanceof Agent)
        {
            Agent agent = ((Agent)(request.getSecurityContext().getUserPrincipal()));
            response.getHeaders().add(HttpHeaders.LINK, new Link(URI.create(agent.getURI()), ACL.agent.getURI(), null));

            Resource authorization = getResourceByPropertyValue(agent.getModel(), ACL.mode, null);
            if (authorization != null)
            {
                Resource mode = authorization.getPropertyResourceValue(ACL.mode); // get access mode from authorization
                response.getHeaders().add(HttpHeaders.LINK, new Link(URI.create(mode.getURI()), ACL.mode.getURI(), null));
            }
            else
                if (log.isWarnEnabled()) log.warn("Authorization is null, cannot write response header. Is {} registered?", AuthorizationFilter.class);
        }
        
        List<Object> linkValues = response.getHeaders().get(HttpHeaders.LINK);
        // check whether Link rel=ldt:base is not already set. Link headers might be forwarded by ProxyResourceBase
        if (getLinksByRel(linkValues, LDT.base.getURI()).isEmpty())
        {
            // add Link rel=ldt:base
            response.getHeaders().add(HttpHeaders.LINK, new Link(getApplication().getBaseURI(), LDT.base.getURI(), null));
            // add Link rel=sd:endpoint.
            // TO-DO: The external SPARQL endpoint URL is different from the internal one currently specified as sd:endpoint in the context dataset
            response.getHeaders().add(HttpHeaders.LINK, new Link(request.getUriInfo().getBaseUriBuilder().path("sparql").build(), SD.endpoint.getURI(), null));
            // add Link rel=ldt:ontology, if the ontology URI is specified
            if (getApplication().getOntology() != null)
                response.getHeaders().add(HttpHeaders.LINK, new Link(URI.create(getApplication().getOntology().getURI()), LDT.ontology.getURI(), null));
            // add Link rel=ac:stylesheet, if the stylesheet URI is specified
            if (getApplication().getStylesheet() != null)
                response.getHeaders().add(HttpHeaders.LINK, new Link(URI.create(getApplication().getStylesheet().getURI()), AC.stylesheet.getURI(), null));
        }
        else
        {
            // add Link rel=sd:endpoint.
            if (getLinksByRel(linkValues, SD.endpoint.getURI()).isEmpty() && getDataset().isPresent() && getDataset().get().getService() != null)
                response.getHeaders().add(HttpHeaders.LINK, new Link(URI.create(getDataset().get().getService().getSPARQLEndpoint().getURI()), SD.endpoint.getURI(), null));
        }
    }

    /**
     * Filters <code>Link</code> headers by their <code>rel</code> attribute.
     * 
     * @param linkValues header list
     * @param rel <code>rel</code> value
     * @return filtered header list
     */
    protected List<Link> getLinksByRel(List<Object> linkValues, String rel)
    {
        List relLinks = new ArrayList<>();
        
        if (linkValues != null) linkValues.forEach(linkValue -> {
            try
            {
                Link link = Link.valueOf(linkValue.toString());
                if (link.getRel().equals(rel)) relLinks.add(link);
            }
            catch (URISyntaxException ex)
            {
                // ignore invalid Link headers
            }
        });
        
        return relLinks;
    }
    
    /**
     * Returns RDF resource from a model that has the specified property and value.
     * If there are no such resources, null is returned.
     * 
     * @param model RDF model
     * @param property property
     * @param value value
     * @return RDF resource or null
     */
    protected Resource getResourceByPropertyValue(Model model, Property property, RDFNode value)
    {
        if (model == null) throw new IllegalArgumentException("Model cannot be null");
        if (property == null) throw new IllegalArgumentException("Property cannot be null");
        
        ResIterator it = model.listSubjectsWithProperty(property, value);
        
        try
        {
            if (it.hasNext()) return it.next();
        }
        finally
        {
            it.close();
        }

        return null;
    }
    
    /**
     * Returns the current application.
     * 
     * @return application resource.
     */
    public com.atomgraph.linkeddatahub.apps.model.Application getApplication()
    {
        return app.get();
    }
    
    /**
     * Returns the current (optional) dataset resource.
     * 
     * @return optional dataset
     */
    public Optional<Dataset> getDataset()
    {
        return dataset.get();
    }
    
}
