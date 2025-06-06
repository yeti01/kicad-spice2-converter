<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="text" encoding="UTF-8"/>

  <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz,'"/>
  <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ.'"/>

  <!-- MAIN: Create Netlist -->
  <xsl:template match="/export">
    <!-- PRINT Project Name -->
    <xsl:text>* </xsl:text>
    <xsl:value-of select="translate(substring-before(/export/design/sheet/title_block/source, '.'), $lowercase, $uppercase)"/>
    <xsl:text>&#10;</xsl:text>

    <!-- PRINT .model -->
    <xsl:call-template name="emit-models"></xsl:call-template>

    <!-- PRINT Circuit -->
    <xsl:apply-templates select="components/comp"/>
    <xsl:text>.END</xsl:text>
  </xsl:template>

  <!-- LOOP: Component handling -->
  <xsl:template match="components/comp">
    <xsl:variable name="ref" select="@ref"/>
    <xsl:variable name="value" select="value"/>
    <xsl:variable name="simtype" select="fields/field[@name='Sim.Type']"/>
    <xsl:variable name="simdevice" select="fields/field[@name='Sim.Device']"/>
    <xsl:variable name="simparams" select="concat(fields/field[@name='Sim.Params'], ' ')"/>

    <!-- (1) PRINT Name -->
    <xsl:value-of select="$ref"/>
    <xsl:text> </xsl:text>

    <!-- (2) PRINT Pins -->
    <xsl:choose>
      <xsl:when test="
           starts-with($ref, 'R')
        or starts-with($ref, 'C')
        or starts-with($ref, 'L')">
        <xsl:call-template name="pin-nodes"><xsl:with-param name="ref" select="$ref"/></xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="ordered-pin-nodes"><xsl:with-param name="ref" select="$ref"/></xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>

    <!-- (3) PRINT Value -->
    <xsl:choose>
      <xsl:when test="
           starts-with($ref, 'R')
        or starts-with($ref, 'C')
        or starts-with($ref, 'L')">
        <xsl:choose>
          <xsl:when test="substring($value, string-length($value), 1) = 'M'">
            <xsl:value-of select="translate(concat($value, 'EG'), $lowercase, $uppercase)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="translate($value, $lowercase, $uppercase)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="
           starts-with($ref, 'D')
        or starts-with($ref, 'Q')
        or starts-with($ref, 'J')
        or starts-with($ref, 'M')
        or starts-with($ref, 'X')
        or $simtype='DC'">
        <xsl:value-of select="translate($value, $lowercase, $uppercase)"/>
      </xsl:when>
    </xsl:choose>

    <!-- (4) PRINT Parameters -->
    <xsl:choose>
      <!-- Generic SPICE models-->
      <xsl:when test="$simdevice='SPICE'">
        <xsl:variable name="model" select="substring-before(substring-after($simparams, 'model=&quot;'), '&quot;')"/>
        <xsl:value-of select="translate($model, $lowercase, $uppercase)"/>
      </xsl:when>

      <!-- Source with PULSE waveform -->
      <xsl:when test="$simtype='PULSE'">
        <xsl:variable name="V1" select="substring-before(substring-after($simparams, 'y1='), ' ')"/>
        <xsl:variable name="V2" select="substring-before(substring-after($simparams, 'y2='), ' ')"/>
        <xsl:variable name="TD" select="substring-before(substring-after($simparams, 'td='), ' ')"/>
        <xsl:variable name="TR" select="substring-before(substring-after($simparams, 'tr='), ' ')"/>
        <xsl:variable name="TF" select="substring-before(substring-after($simparams, 'tf='), ' ')"/>
        <xsl:variable name="TW" select="substring-before(substring-after($simparams, 'tw='), ' ')"/>
        <xsl:variable name="PER" select="substring-before(substring-after($simparams, 'per='), ' ')"/>
        <xsl:text>PULSE(</xsl:text>
        <xsl:value-of select="field[@name='Sim.Params']"/>
        <xsl:value-of select="translate($V1, $lowercase, $uppercase)"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="translate($V2, $lowercase, $uppercase)"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="translate($TD, $lowercase, $uppercase)"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="translate($TR, $lowercase, $uppercase)"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="translate($TF, $lowercase, $uppercase)"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="translate($TW, $lowercase, $uppercase)"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="translate($PER, $lowercase, $uppercase)"/>
        <xsl:text>)</xsl:text>
      </xsl:when>

      <!-- Source with SIN waveform -->
      <xsl:when test="$simtype='SIN'">
        <xsl:variable name="VO" select="substring-before(substring-after($simparams, 'dc='), ' ')"/>
        <xsl:variable name="VA" select="substring-before(substring-after($simparams, 'ampl='), ' ')"/>
        <xsl:variable name="FREQ" select="substring-before(substring-after($simparams, 'f='), ' ')"/>
        <xsl:text>SIN(</xsl:text>
        <xsl:value-of select="translate($VO, $lowercase, $uppercase)"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="translate($VA, $lowercase, $uppercase)"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="translate($FREQ, $lowercase, $uppercase)"/>
        <xsl:text>)</xsl:text>
      </xsl:when>

      <!-- Source with EXP waveform -->
      <xsl:when test="$simtype='EXP'">
        <xsl:variable name="V1" select="substring-before(substring-after($simparams, 'y1='), ' ')"/>
        <xsl:variable name="V2" select="substring-before(substring-after($simparams, 'y2='), ' ')"/>
        <xsl:variable name="TD1" select="substring-before(substring-after($simparams, 'td1='), ' ')"/>
        <xsl:variable name="TAU1" select="substring-before(substring-after($simparams, 'tau1='), ' ')"/>
        <xsl:variable name="TD2" select="substring-before(substring-after($simparams, 'td2='), ' ')"/>
        <xsl:variable name="TAU2" select="substring-before(substring-after($simparams, 'tau2='), ' ')"/>
        <xsl:text>EXP(</xsl:text>
        <xsl:value-of select="field[@name='Sim.Params']"/>
        <xsl:value-of select="translate($V1, $lowercase, $uppercase)"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="translate($V2, $lowercase, $uppercase)"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="translate($TD1, $lowercase, $uppercase)"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="translate($TAU1, $lowercase, $uppercase)"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="translate($TD2, $lowercase, $uppercase)"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="translate($TAU2, $lowercase, $uppercase)"/>
        <xsl:text>)</xsl:text>
      </xsl:when>

      <!-- Source with PWL waveform -->
      <xsl:when test="$simtype='PWL'">
        <xsl:text>PWL(</xsl:text>
        <xsl:variable name="pwl" select="substring-before(substring-after($simparams, 'pwl=&quot;'), '&quot;')"/>
        <xsl:value-of select="translate($pwl, $lowercase, $uppercase)"/>
        <xsl:text>)</xsl:text>
      </xsl:when>
    </xsl:choose>

    <!-- (5) PRINT New Line -->
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <!-- FUNCTION: Model definitions -->
  <xsl:template name="emit-models">
    <xsl:for-each select="/export/components/comp[property[@name='Sim.Device'
     and(@value='D'
      or @value='NPN'
      or @value='PNP'
      or @value='NJF'
      or @value='NJFET'
      or @value='PJF'
      or @value='PJFET'
      or @value='NMOS'
      or @value='PMOS')]]">
      <xsl:variable name="modelname" select="value"/>
      <xsl:variable name="modeldevice" select="property[@name='Sim.Device']/@value"/>
      <xsl:variable name="modelparams" select="property[@name='Sim.Params']/@value"/>

      <!-- Avoid duplicate model declarations -->
      <xsl:if test="value[not(. = preceding::value)]">
        <xsl:text>.MODEL </xsl:text>
        <xsl:value-of select="$modelname"/>
        <xsl:text> </xsl:text>
        <xsl:choose>
          <xsl:when test="$modeldevice='NJFET'">
            <xsl:text>NJF</xsl:text>
          </xsl:when>
          <xsl:when test="$modeldevice='PJFET'">
            <xsl:text>PJF</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$modeldevice"/>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="string-length(normalize-space($modelparams)) &gt; 0">
          <xsl:text>(</xsl:text>
          <xsl:call-template name="split-model-parameters">
            <xsl:with-param name="params" select="translate($modelparams, $lowercase, $uppercase)"/>
          </xsl:call-template>
          <xsl:text>)</xsl:text>
        </xsl:if>
        <xsl:text>&#10;</xsl:text>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <!-- FUNCTION: Split model parameters into separate lines -->
  <xsl:template name="split-model-parameters">
    <xsl:param name="params"/>
    <xsl:choose>
      <!-- If the string contains a space -->
      <xsl:when test="contains($params, ' ')">
        <xsl:value-of select="substring-before($params, ' ')"/>
        <xsl:text>&#10;+ </xsl:text> <!-- newline and plus -->
        <!-- Recurse with rest of the string -->
        <xsl:call-template name="split-model-parameters">
          <xsl:with-param name="params" select="substring-after($params, ' ')"/>
        </xsl:call-template>
      </xsl:when>
      <!-- Last part of the string -->
      <xsl:otherwise>
        <xsl:value-of select="$params"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- FUNCTION: Node names for pins -->
  <xsl:template name="pin-nodes">
    <xsl:param name="ref"/>
    <xsl:for-each select="/export/nets/net/node[@ref = $ref]">
      <xsl:sort select="@pin"/>
      <xsl:variable name="net" select=".."/>
      <xsl:choose>
        <xsl:when test="$net/@name='0' or $net/@name='GND'">
          <xsl:text>0</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$net/@code"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:text> </xsl:text>
    </xsl:for-each>
  </xsl:template>

  <!-- FUNCTION: Ordered node names for pins -->
  <xsl:template name="ordered-pin-nodes">
    <xsl:param name="ref"/>
    <xsl:variable name="pinspec" select="/export/components/comp[@ref = $ref]/fields/field[@name = 'Sim.Pins']"/>
    <xsl:call-template name="process-pins">
      <xsl:with-param name="pinspec" select="$pinspec"/>
      <xsl:with-param name="ref" select="$ref"/>
    </xsl:call-template>
  </xsl:template>

  <!-- FUNCTION: Helper to process pins -->
  <xsl:template name="process-pins">
    <xsl:param name="pinspec"/>
    <xsl:param name="ref"/>

    <!-- Get the first token -->
    <xsl:variable name="this" select="substring-before(concat($pinspec, ' '), ' ')"/>
    <xsl:variable name="rest" select="substring-after($pinspec, ' ')"/>
    <xsl:if test="$this != ''">
      <xsl:variable name="pin" select="substring-before($this, '=')"/>

      <!-- Lookup the node for this pin -->
      <xsl:for-each select="/export/nets/net">
        <xsl:for-each select="node[@ref = $ref and @pin = $pin]">
          <xsl:choose>
            <xsl:when test="../@name = '0' or ../@name = 'GND'">
              <xsl:text>0 </xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="../@code"/>
              <xsl:text> </xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </xsl:for-each>

      <!-- Recurse for next token -->
      <xsl:call-template name="process-pins">
        <xsl:with-param name="pinspec" select="$rest"/>
        <xsl:with-param name="ref" select="$ref"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>
</xsl:stylesheet>
