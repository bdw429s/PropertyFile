/**
* I am a transient representation of the contents of a property file .
* Create a new version of me for separate property files.  I can be intercted with via
* methods or public properties that represent the keys.
*
* https://fmpp.sourceforge.net/properties.html
*/
component accessors="true"{

	// A fully qualified path to a property file
	property name='path';
	property name='syncedNames';
	// An array of structs representing the lines in the property file
	property name='lines' type='array';
	property name='maxLineWidth' default='150';
	property name='lineSeparator';



	/**
	 * Constructor
	 */
	PropertyFile function init(){
		setMaxLineWidth( 150 );
		setLines( [] );
		setSyncedNames( [] );
		var os = createObject('java', 'java.lang.System').getProperty('os.name', '');

		if( os contains 'win' ) {
			setLineSeparator( chr( 13 ) & chr( 10 ) );
		} else if( os contains 'mac' ) {
			setLineSeparator( chr( 13 ) );
		} else {
			setLineSeparator( chr( 10 ) );
		}
		return this;
	}

	/**
	 * Add line from source file to object
	 *
	 * @contents Text from line
	 * @lineNo Source line number
	 */
	private function addLine( required string contents, required numeric lineNo, required string originalLine ){
		var line = {
			'type' : '',
			'value' : ''
		};
		if( contents.startsWith( '##' ) || contents.startsWith( '!' ) ) {
			line.type = 'comment';
			line.value = contents;
		} else if( trim( contents ) == '') {
			line.type = 'whitespace';
			line.value = contents;
		// Contains a non-escaped : or =
		} else {
			// Look for the first = or : or <space> that is not escaped by a \
			// unless it's a space immediatley followed by a = or :, in which case nevermind, use the = or :
			// foo=bar
			// foo:bar
			// foo bar
			// foo = bar
			// foo : bar
			// foo \bar=baz   -> kay name is "foo bar"
			var delimSearch = contents.reFind( '[^\\](([=:])|([ ][^=:]))' );
			if( delimSearch ) {
				line['name'] = unEscapeToken( rtrim( contents.substring( 0, delimSearch ) ) );
				line['delimiter'] = contents.mid( delimSearch+1, 1 );
				line.value = unEscapeToken( ltrim( contents.substring( delimSearch + 1 ) ) );
				line.type = 'property';
				line['originalLine'] = originalLine;
			} else {
				throw( "Invalid property file format, line #lineNo#" );
			}
		}
		getLines().append( line );
	}

	private function unEscapeToken( required string token ) {
		var escaped = false;
		var unicode = false;
		var unicodeString = '';
		cfSaveContent( variable="local.result" ) {
			for( var char in token.listToArray( '' ) ) {
				if( !escaped && !unicode && char == '\' ) {
					escaped=true;
				} else if( escaped && !unicode ) {
					// valid escapes are
					// \t, \n, \r, \f, \\, \", \', and \uxxxx
					if( char == 't' ) {
						// tab
						writeOutput( chr( 9 ) );
					} else if( char == 'n' ) {
						// newline
						writeOutput( chr( 10 ) );
					} else if( char == 'r' ) {
						// carriage return
						writeOutput( chr( 13 ) );
					} else if( char == 'f' ) {
						// form feed
						writeOutput( chr( 12 ) );
					} else if( char == '\' ) {
						writeOutput( '\' );
					} else if( char == '"' ) {
						writeOutput( '"' );
					} else if( char == "'" ) {
						writeOutput( "'" );
					} else if( char == 'u' ) {
						unicode = true
					} else {
						writeOutput( char );
					}
					escaped=false;
				} else if( unicode ) {
					if( !char.reFindNoCase( '[0-9a-f]' ) ) {
						throw( 'Invalid unicode character [#char#] in token [#token#]' );
					}
					unicodeString &= char;
					if( len( unicodeString ) == 4 ) {
						writeOutput( chr( inputBaseN(unicodeString, 16) ) );
						unicodeString = '';
						unicode = false;
					}
				} else {
					writeOutput( char );
				}
			}
			if( unicode ) {
				throw( 'incomplete unicode escape at the end of token [#token#]' );
			}
		}
		return local.result;
	}

	/**
	* @load A fully qualified path to a property file
	*/
	function load( required string path){
		setPath( arguments.path );
		var fileContents = fileRead( arguments.path )
			.replace( chr( 13 ) & chr( 10 ), chr( 10 ), 'all' )
			.replace( chr( 13 ), chr( 10 ), 'all' );
		var lines = fileContents.listToArray( chr( 10 ), true );
		var lineNo = 0;
		var nextLine = '';
		var originalLine = '';
		for( var line in lines ) {
			lineNo++;
			originalLine &= line;
			nextLine &= ltrim( line );
			if( nextLine.endsWith( '\' ) ) {
				nextLine = nextLine.left( -1 );
				originalLine &= chr( 10 );
				continue;
			} else {
				addLine( nextLine, lineNo, originalLine.replace( chr( 10 ), lineSeparator, 'all' ) );
				originalLine = '';
				nextLine = '';
			}
		}

		var syncedNames = getSyncedNames();
		_getAsStruct().each( ( key, value ) => {
			this[ key ] = value;
			if( !arrayContains( syncedNames, key ) ){
				syncedNames.append( key );
			}
		} );
		setSyncedNames( syncedNames );

		return this;
	}

	/**
	* @load A fully qualified path to a property file.  File will be created if it doesn't exist.
	*/
	function store( string path=variables.path ){
		syncProperties();

		var dir = getDirectoryFromPath( arguments.path );
		if( !directoryExists( dir ) ) {
			directoryCreate( dir );
		}
		fileWrite( arguments.path, getLinesAsText() );

		return this;
	}

	private function getLinesAsText(){
		var lineSeparator = getLineSeparator();
		var result = '';
		var noLines = getLines().len();
		var lineNo = 0;
		for( var line in getLines() ) {
			lineNo++;
			if( line.type == 'comment' ) {
				result &= line.value;
			} else if( line.type == 'whitespace' ) {
				result &= line.value;
			} else if( line.type == 'property' ) {
				if( line.keyExists( 'originalLine' ) ) {
					result &= line.originalLine;
				} else {
					var name = escapeToken( line.name, true );
					result &= name & line.delimiter & breakLongLine( escapeToken( line.value ), len(name)+1 );
				}
			}
			if( lineNo < noLines ) {
				result &= lineSeparator;
			}
		}
		return result;
	}

	private function breakLongLine( required string text, numeric padding ) {
		var lineSeparator = getLineSeparator();
		var len = len( text ) + padding;
		var result = '';
		while( len > getMaxLineWidth() ) {
			var prefix = '';
			if( len( result ) ) {
				prefix = repeatString( ' ', padding );
			}
			var cutPoint = getMaxLineWidth() - padding;
			// Don't cut right before a space since it will be eroneously removed from the start of the wrapped line
			while( cutPoint < len( text ) && text.mid( cutPoint+1, 1 ) == ' ' ) {
				cutPoint++;
			}
			// in case there was only whitespace after the last cut point, only cut if our cutpoint is not all the way to the end
			if( cutPoint < len( text ) ) {
				result &= prefix & text.left( cutPoint ) & '\' & lineSeparator;
				text = text.mid( cutPoint + 1, len( text ) );
				len = len( text ) + padding;
			}
		}
		if( len( result ) ){
			result &= repeatString( ' ', padding ) & text;
		} else {
			result = text;
		}
		return result;
	}

	private function escapeToken( required string token, boolean escapeName=false ) {
		var result = '';
		for( var char in token.listToArray( '' ) ) {
			result &= escapeChar( char, arguments.escapeName );
		}
		return result;
	}

	private function escapeChar( required string char, boolean escapeName=false ) {
		var codePoint = asc(char);
		if( codePoint == 9 ) {
			return '\t';
		} else if( codePoint == 10 ) {
			return '\n';
		} else if( codePoint == 13 ) {
			return '\r';
		} else if( codePoint == 12 ) {
			return '\f';
		} else if( codePoint == 34 ) {
			return '\"';
		} else if( codePoint == 39 ) {
			return "\'";
		} else if( codePoint == 92 ) {
			return '\\';
		} else if( escapeName && codePoint == 32 ) {
			return '\ ';
		} else if( escapeName && codePoint == 61 ) {
			return '\=';
		} else if( escapeName && codePoint == 58 ) {
			return '\:';
		} else if( codePoint > 255) {
			var hexString=formatBaseN( codePoint, 16 );
			return '\u' & repeatString( "0", 4 - len( hexString ) ) & hexString;
		} else {
			return char;
		}
	}

	/**
	* get
	*/
	function get( required string name, string defaultValue ){
		syncProperties();
		var data = _getAsStruct();
		if( structKeyExists( data, arguments.name ) ) {
			return data[ name ];
		} else if( structKeyExists( arguments, 'defaultValue' ) ) {
			return defaultValue;
		} else {
			throw 'Key [#name#] does not exist in this properties file. Valid keys are #structKeyList( data )#';
		}
	}

	/**
	* set
	*/
	function set( required string name, required string value ){
		var line = findLineNo( name );
		if( line ) {
			var lineData = getLines()[line];
			if( lineData.value != arguments.value ) {
				lineData.value = arguments.value;
				lineData.delete( 'originalLine' );
			}
		} else {
			line = {
				'type' : 'property',
				'name' : arguments.name,
				'value' : arguments.value,
				'delimiter' : '='
			};
			getLines().append( line );
		}
		var syncedNames = getSyncedNames();
		this[ name ] = value;
		if( !arrayContains( syncedNames, name ) ){
			syncedNames.append( name );
		}
		setSyncedNames( syncedNames );

		return this;
	}

	/**
	* clear
	*/
	function remove( required string name ){
		var line = findLineNo( name );
		if( line ) {
			getLines().deleteAt( line );

			var syncedNames = getSyncedNames();
			if( arrayFind( syncedNames, name ) ){
				syncedNames.deleteAt( arrayFind( syncedNames, name ) );
			}
			setSyncedNames( syncedNames );
			structDelete( this, name );
		}
		return this;
	}

	private function findLineNo( required string name ) {
		return getLines().find( (l)=>{
			return l.type=='property' && l.name==name;
		 } );
	}

	/**
	* exists
	*/
	function exists( required string name ){
		return findLineNo( name ) > 0;
	}

	/**
	* getAsStruct
	*/
	function getAsStruct(){
		syncProperties();
		return _getAsStruct();
	}

	private function _getAsStruct(){
		return getLines()
			.filter((l)=>l.type=='property')
			.reduce((s,l)=>{
				s[l.name]=l.value;
				return s;
			},
			[:]);
	}

	/**
	* mergeStruct
	*/
	function mergeStruct( struct incomingStruct ){
		incomingStruct.each( ( key, value ) => {
			set( key, value );
		} );
		syncProperties();
		return this;
	}

	/**
	* Keeps public properties in sync with Java object
	*/
	private function syncProperties() {
		var syncedNames = getSyncedNames();
		var ignore = listToArray( 'init,load,store,get,set,exists,remove,exists,getAsStruct,$mixed,mergeStruct' );
		var data = _getAsStruct();

		// This CFC's public properties
		for( var prop in this ) {
			// Set any new/updated properties in, excluding actual methods and non-simple values
			if( !ignore.findNoCase( prop ) && isSimpleValue( this[ prop ] ) ) {
				set( prop, this[ prop ] );
			}
		}

		// All the properties in the data
		for( var prop in data.keyArray() ) {
			// Remove any properties that were deleted off the CFC's public scope
			if( !structKeyExists( this, prop ) ) {
				remove( prop );
			}
		}

	}

}