#!/usr/bin/make -f
#
# Title:  Citation List Extractor
# Author: Vít Novotný
#
# Process *.bib and *.aux files in the current working directory to produce
# a list of references in the CSTUG XML format given in `bulletin.rng`. Barring
# any errors, the resulting list will be stored in the file
# `extract-citations_result.xml`.
#
# Requires GNU Make, GNU Bash, GNU sed, GNU awk, biber, xsltproc, and xmllint.

PREFIX=extract-citations
SHELL=/bin/bash

# Although the defaults seem to work ok, perhaps add a --configfile with extra
# non-default options for biber later?
BIBER_OPTIONS=--tool --isbn-normalise --nodieonerror --output-format=biblatexml

.ONESHELL:
.PHONY: all
all: $(PREFIX)_result.xml

$(PREFIX)_result.xml: $(PREFIX).xsl $(PREFIX).xml
	# The sed filter in the middle is a coy attempt at turning LaTeX text into
	# plaintext. Perhaps to be replaced with a more clever filter later?
	xsltproc --xinclude $^ | sed 's/[{}]//g' | xmllint --format - >$@

$(PREFIX)_prefilter_result.bltxml: $(PREFIX)_prefilter.xsl $(PREFIX)_prefilter.xml
	xsltproc --xinclude $^ | xmllint --format - >$@

# A transformation that takes a document that represents citations with an
# unfiltered bibliography database with resolved crossref entries and
# produces a list of references in the CSTUG XML format.
$(PREFIX).xsl:
	cat <<-'EOF' >$@
	  <?xml version="1.0" encoding="UTF-8"?>
	  <xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	                               xmlns:bltx="http://biblatex-biber.sourceforge.net/biblatexml">
	    <xsl:output method="xml" encoding="UTF-8"/>
	    <xsl:template match="/citations">
	      <citation_list>
	        <xsl:apply-templates select="bibcites"/>
	      </citation_list>
	    </xsl:template>
	  
	    <xsl:template match="bibcites">
	      <xsl:apply-templates select="bibcite"/>
	    </xsl:template>
	  
	    <xsl:template match="bibcite">
	      <citation>
	        <xsl:apply-templates select="/citations/bltx:entries/bltx:entry[@id=current()/text()]"/>
	      </citation>
	    </xsl:template>
	  
	    <xsl:template match="bltx:entry">
	      <!-- No crossrefs should actually remain in the BibLaTeXML bibliography
	           database with resolved crossref entries. -->
	      <xsl:apply-templates select="bltx:crossref"/>
	      <xsl:choose>
	        <xsl:when test="bltx:doi">
	          <xsl:apply-templates select="bltx:doi"/>
	        </xsl:when>
	        <xsl:otherwise>
	          <xsl:apply-templates select="bltx:issn"/>
	          <xsl:apply-templates select="bltx:journaltitle"/>
	          <xsl:if test="bltx:names">
	            <contributors>
	              <xsl:apply-templates select="bltx:names[@type='author']">
	                <xsl:with-param name="possibly_first">true</xsl:with-param>
	              </xsl:apply-templates>
	      
	              <xsl:choose>
	                <xsl:when test="not(bltx:names[@type='author'])">
	                  <xsl:apply-templates select="bltx:names[@type='editor']">
	                    <xsl:with-param name="possibly_first">true</xsl:with-param>
	                  </xsl:apply-templates>
	                </xsl:when>
	                <xsl:otherwise>
	                  <xsl:apply-templates select="bltx:names[@type='editor']">
	                    <xsl:with-param name="possibly_first">false</xsl:with-param>
	                  </xsl:apply-templates>
	                </xsl:otherwise>
	              </xsl:choose>
	      
	              <xsl:choose>
	                <xsl:when test="not(bltx:names[@type='author']) and
	                                not(bltx:names[@type='editor'])">
	                  <xsl:apply-templates select="bltx:names[@type='editora']">
	                    <xsl:with-param name="possibly_first">true</xsl:with-param>
	                  </xsl:apply-templates>
	                </xsl:when>
	                <xsl:otherwise>
	                  <xsl:apply-templates select="bltx:names[@type='editora']">
	                    <xsl:with-param name="possibly_first">false</xsl:with-param>
	                  </xsl:apply-templates>
	                </xsl:otherwise>
	              </xsl:choose>
	      
	              <xsl:choose>
	                <xsl:when test="not(bltx:names[@type='author']) and
	                                not(bltx:names[@type='editor']) and
	                                not(bltx:names[@type='editora'])">
	                  <xsl:apply-templates select="bltx:names[@type='editorb']">
	                    <xsl:with-param name="possibly_first">true</xsl:with-param>
	                  </xsl:apply-templates>
	                </xsl:when>
	                <xsl:otherwise>
	                  <xsl:apply-templates select="bltx:names[@type='editorb']">
	                    <xsl:with-param name="possibly_first">false</xsl:with-param>
	                  </xsl:apply-templates>
	                </xsl:otherwise>
	              </xsl:choose>
	      
	              <xsl:choose>
	                <xsl:when test="not(bltx:names[@type='author']) and
	                                not(bltx:names[@type='editor']) and
	                                not(bltx:names[@type='editora']) and
	                                not(bltx:names[@type='editorb'])">
	                  <xsl:apply-templates select="bltx:names[@type='editorc']">
	                    <xsl:with-param name="possibly_first">true</xsl:with-param>
	                  </xsl:apply-templates>
	                </xsl:when>
	                <xsl:otherwise>
	                  <xsl:apply-templates select="bltx:names[@type='editorc']">
	                    <xsl:with-param name="possibly_first">false</xsl:with-param>
	                  </xsl:apply-templates>
	                </xsl:otherwise>
	              </xsl:choose>
	      
	              <xsl:choose>
	                <xsl:when test="not(bltx:names[@type='author']) and
	                                not(bltx:names[@type='editor']) and
	                                not(bltx:names[@type='editora']) and
	                                not(bltx:names[@type='editorb']) and
	                                not(bltx:names[@type='editorc'])">
	                  <xsl:apply-templates select="bltx:names[@type='translator']">
	                    <xsl:with-param name="possibly_first">true</xsl:with-param>
	                  </xsl:apply-templates>
	                </xsl:when>
	                <xsl:otherwise>
	                  <xsl:apply-templates select="bltx:names[@type='translator']">
	                    <xsl:with-param name="possibly_first">false</xsl:with-param>
	                  </xsl:apply-templates>
	                </xsl:otherwise>
	              </xsl:choose>
	            </contributors>
	          </xsl:if>
	          <xsl:apply-templates select="bltx:volume"/>
	          <xsl:apply-templates select="bltx:number"/>
	          <xsl:if test="normalize-space(bltx:pages/bltx:list/bltx:item/bltx:start/text())">
	            <xsl:apply-templates select="bltx:pages/bltx:list/bltx:item/bltx:start"/>
	          </xsl:if>
	          <xsl:apply-templates select="bltx:date[not(@type)]"/>
	          <xsl:apply-templates select="bltx:isbn"/>
	          <xsl:apply-templates select="bltx:series"/>
	          <xsl:apply-templates select="bltx:booktitle"/>
	          <xsl:apply-templates select="bltx:edition"/>
	          <xsl:if test="bltx:title | bltx:subtitle">
	            <article_title>
	              <xsl:apply-templates select="bltx:title"/><xsl:if test="bltx:subtitle">: <xsl:apply-templates select="bltx:subtitle"/></xsl:if>
	            </article_title>
	          </xsl:if>
	          <xsl:if test="bltx:url">
	            <additionalcontent>
	              <xsl:apply-templates select="bltx:url"/>
	            </additionalcontent>
	          </xsl:if>
	        </xsl:otherwise>
	      </xsl:choose>
	    </xsl:template>
	  
	    <xsl:template match="bltx:journaltitle">
	      <journal_title><xsl:value-of select="text()"/></journal_title>
	    </xsl:template>
	  
	    <xsl:template match="bltx:names">
	      <xsl:param name="possibly_first"/>
	      <xsl:apply-templates select="bltx:name">
	        <xsl:with-param name="possibly_first">
	          <xsl:value-of select="$$possibly_first"/>
	        </xsl:with-param>
	      </xsl:apply-templates>
	    </xsl:template>
	  
	    <xsl:template match="bltx:name">
	      <xsl:param name="possibly_first"/>
	      <person_name>
	        <xsl:choose>
	          <xsl:when test="../@type = 'author'">
	            <xsl:attribute name="contributor_role">author</xsl:attribute>
	          </xsl:when>
	          <xsl:when test="../@type = 'translator'">
	            <xsl:attribute name="contributor_role">translator</xsl:attribute>
	          </xsl:when>
	          <xsl:otherwise>
	            <xsl:attribute name="contributor_role">editor</xsl:attribute>
	          </xsl:otherwise>
	        </xsl:choose>
	        <xsl:choose>
	          <xsl:when test="normalize-space($$possibly_first) = 'true' and position() = 1">
	            <xsl:attribute name="sequence">first</xsl:attribute>
	          </xsl:when>
	          <xsl:otherwise>
	            <xsl:attribute name="sequence">additional</xsl:attribute>
	          </xsl:otherwise>
	        </xsl:choose>
	        <xsl:apply-templates select="bltx:namepart[@type='given']"/>
	        <surname><xsl:apply-templates select="bltx:namepart[@type='family']/node()"/></surname>
	        <xsl:apply-templates select="bltx:namepart[@type='suffix']"/>
	      </person_name>
	    </xsl:template>
	  
	    <xsl:template match="bltx:namepart[@type='given']">
	      <given_name><xsl:apply-templates select="node()"/></given_name>
	    </xsl:template>
	  
	    <xsl:template match="bltx:namepart[@type='suffix']">
	      <suffix><xsl:apply-templates select="node()"/></suffix>
	    </xsl:template>
	  
	    <xsl:template match="bltx:volume">
	      <volume><xsl:value-of select="text()"/></volume>
	    </xsl:template>
	  
	    <xsl:template match="bltx:number">
	      <issue><xsl:value-of select="text()"/></issue>
	    </xsl:template>
	  
	    <xsl:template match="bltx:pages/bltx:list/bltx:item/bltx:start">
	      <first_page><xsl:value-of select="text()"/></first_page>
	    </xsl:template>
	  
	    <xsl:template match="bltx:date">
	      <cYear><xsl:value-of select="substring(text(), 1, 4)"/></cYear>
	    </xsl:template>
	  
	    <xsl:template match="bltx:doi">
	      <doi><xsl:value-of select="text()"/></doi>
	    </xsl:template>
	  
	    <xsl:template match="bltx:isbn">
	      <isbn media_type="print"><xsl:value-of select="text()"/></isbn>
	    </xsl:template>
	  
	    <xsl:template match="bltx:issn">
	      <issn media_type="print"><xsl:value-of select="text()"/></issn>
	    </xsl:template>
	  
	    <xsl:template match="bltx:series">
	      <series_title><xsl:value-of select="text()"/></series_title>
	    </xsl:template>
	  
	    <xsl:template match="bltx:booktitle">
	      <volume_title><xsl:value-of select="text()"/></volume_title>
	    </xsl:template>
	  
	    <xsl:template match="bltx:edition">
	      <edition_number><xsl:value-of select="text()"/></edition_number>
	    </xsl:template>
	  
	    <xsl:template match="bltx:title | bltx:subtitle">
	      <xsl:value-of select="text()"/>
	    </xsl:template>
	  
	    <xsl:template match="bltx:crossref">
	      <xsl:comment> crossref: <xsl:value-of select="text()"/><xsl:text> </xsl:text></xsl:comment>
	    </xsl:template>
	  
	    <xsl:template match="bltx:url">
	      <url>
	        <xsl:if test="../bltx:date[@type='url']">
	          <xsl:attribute name="cited">
	            <xsl:value-of select="../bltx:date[@type='url']"/>
	          </xsl:attribute>
	        </xsl:if>
	        <xsl:value-of select="text()"/>
	      </url>
	    </xsl:template>
	  
	  </xsl:transform>
	EOF

# A transformation that takes a document that represents citations with an
# unfiltered bibliography database with unresolved crossref entries and
# produces a filtered BibLaTeXML database with unresolved crossref entries.
$(PREFIX)_prefilter.xsl:
	cat <<-'EOF' >$@
	  <?xml version="1.0" encoding="UTF-8"?>
	  <xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	                               xmlns:bltx="http://biblatex-biber.sourceforge.net/biblatexml">
	    <xsl:output method="xml" encoding="UTF-8"/>
	    <xsl:template match="/citations">
	      <bltx:entries>
	        <xsl:apply-templates select="bibcites"/>
	      </bltx:entries>
	    </xsl:template>
	  
	    <xsl:template match="bibcites">
	      <xsl:apply-templates select="bibcite"/>
	    </xsl:template>
	  
	    <xsl:template match="bibcite">
	      <xsl:apply-templates select="/citations/bltx:entries/bltx:entry[@id=current()/text()]"/>
	    </xsl:template>
	  
	    <xsl:template match="bltx:entry">
	      <bltx:entry>
	        <xsl:copy-of select="node()|@*"/>
	      </bltx:entry>
	      <xsl:apply-templates select="../bltx:entry[@id = current()/bltx:crossref/text()]"/>
	    </xsl:template>
	  
	  </xsl:transform>
	EOF

# A document that represents citations with an unfiltered bibliography
# database with unresolved crossref entries.
$(PREFIX)_prefilter.xml: $(PREFIX)_prefilter_bibertool.bltxml $(PREFIX)_bibcites.xml
	cat <<-'EOF' >$@
	  <?xml version="1.0" encoding="utf-8"?>
	  <citations xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	             xmlns:xi="http://www.w3.org/2001/XInclude">
	      <xi:include href="$(PREFIX)_bibcites.xml" />
	      <xi:include href="$(PREFIX)_prefilter_bibertool.bltxml" />
	  </citations>
	EOF

# A document that represents citations with a filtered bibliography
# database with resolved crossref entries.
$(PREFIX).xml: $(PREFIX)_bibertool.bltxml $(PREFIX)_bibcites.xml
	cat <<-'EOF' >$@
	  <?xml version="1.0" encoding="utf-8"?>
	  <citations xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	             xmlns:xi="http://www.w3.org/2001/XInclude">
	      <xi:include href="$(PREFIX)_bibcites.xml" />
	      <xi:include href="$(PREFIX)_bibertool.bltxml" />
	  </citations>
	EOF

# Transform the unfiltered BibTeX bibliography database with unresolved
# crossref entries to an unfiltered BibLaTeXML bibliography database with
# unresolved crossref entries.
$(PREFIX)_prefilter_bibertool.bltxml: $(PREFIX)_prefilter.bib
	biber --input-format=bibtex $(BIBER_OPTIONS) $<

# Transform the filtered BibLaTeXML bibliography to a filtered BibLaTeXML
# bibliography database with resolved crossref entries.
$(PREFIX)_bibertool.bltxml: $(PREFIX)_prefilter_result.bltxml
	set -e
	biber --input-format=biblatexml --output-resolve $(BIBER_OPTIONS) $<
	mv $(PREFIX)_prefilter_result_bibertool.bltxml $@

# Extract all bibliography entries from *.bib files to form an unfiltered
# BibTeX bibliography database with unresolved crossref entries.
$(PREFIX)_prefilter.bib: *.bib
	set -e
	shopt -s extglob
	cat !($(PREFIX)_prefilter).bib >$@

# Extract citations from the *.aux files.
$(PREFIX)_bibcites.xml: *.aux
	sed -nr '
	  /^\\bibcite/s/\\bibcite\{([^}]*)\}\{[0-9]*\}$$/\1/p;
	  /^\\abx@aux@cite/s/\\abx@aux@cite\{([^}]*)\}$$/\1/p' $^ | \
	awk '
	  BEGIN {
	    print "<bibcites>"}
	  END {
	    print "</bibcites>"}
	  !seen[$$0]++ {
	    print "<bibcite>" $$0 "</bibcite>"}' >$@
