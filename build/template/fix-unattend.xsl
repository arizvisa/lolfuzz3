<?xml version="1.0"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:ns="urn:schemas-microsoft-com:unattend"
  xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
  xmlns="urn:schemas-microsoft-com:unattend">

  <!-- variables -->
  <xsl:variable name="space">102400</xsl:variable>

  <xsl:variable name="root-user">root</xsl:variable>
  <xsl:variable name="root-pass">
    <Value>default password</Value>
    <PlainText>true</PlainText>
  </xsl:variable>

  <xsl:variable name="regular-user">user</xsl:variable>
  <xsl:variable name="regular-pass">
    <Value>default password</Value>
    <PlainText>true</PlainText>
  </xsl:variable>

  <!-- auto-logon template -->
  <xsl:template name="AutoLogon">
    <Enabled>true</Enabled>
    <Username><xsl:value-of select="$root-user" /></Username>
    <Password><xsl:copy-of select="$root-pass" /></Password>
  </xsl:template>

  <!-- identity template -->
  <xsl:template name="identity" match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>

  <!-- disk partition size -->
  <xsl:template match="//ns:DiskConfiguration//ns:CreatePartition/ns:Size">
    <xsl:copy><xsl:value-of select="$space" /></xsl:copy>
  </xsl:template>

  <!-- auto logon account -->
  <xsl:template match="//ns:AutoLogon">
    <xsl:copy>
      <xsl:call-template name="AutoLogon" />
    </xsl:copy>
  </xsl:template>

  <!-- account information -->
  <xsl:template match="//ns:UserAccounts">
    <xsl:copy>
      <xsl:apply-templates select="ns:LocalAccounts" />
      <xsl:apply-templates select="ns:AdministratorPassword" />
    </xsl:copy>
  </xsl:template>

  <xsl:template match="ns:LocalAccounts">
    <xsl:copy>
      <xsl:call-template name="root" />
      <xsl:apply-templates select="ns:LocalAccount" />
    </xsl:copy>
  </xsl:template>

  <xsl:template match="ns:AdministratorPassword">
    <xsl:copy>
      <xsl:copy-of select="$root-pass" />
    </xsl:copy>
  </xsl:template>

  <!-- add a root user -->
  <xsl:template name="root">
    <LocalAccount wcm:action="add">
        <Name><xsl:value-of select="$root-user" /></Name>
        <Group>Administrators</Group>
        <DisplayName><xsl:value-of select="$root-user" /></DisplayName>
        <Description>root user</Description>
        <Password><xsl:copy-of select="$root-pass" /></Password>
    </LocalAccount>
  </xsl:template>

  <!-- replace the vagrant user with a regular one -->
  <xsl:template match="ns:LocalAccount[./ns:Name='vagrant']">
    <xsl:copy>
      <xsl:copy-of select="@*" />
      <Name><xsl:value-of select="$regular-user" /></Name>
      <Group>Users</Group>
      <DisplayName><xsl:value-of select="$regular-user" /></DisplayName>
      <Description>regular user</Description>
      <Password><xsl:copy-of select="$regular-pass" /></Password>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
