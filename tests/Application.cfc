/**
 * Copyright Since 2005 Ortus Solutions, Corp
 * www.ortussolutions.com
 * *************************************************************************************
 */
component {

	this.name              = "ProprtyFile Runner Suite";

	// any mappings go here, we create one that points to the root called test.
	this.mappings[ "/tests" ] = getDirectoryFromPath( getCurrentTemplatePath() );
	this.mappings[ "/root" ] = expandPath( "/" );

}
