/**
 * My first spec file
 */
component extends="testbox.system.BaseSpec" {

	function run() {

		describe( "property file", () => {

			it( "can read a basic file", () => {
				var propertyFile = new models.PropertyFile().load( expandPath( '/tests/resources/sample.properties' ) );
				var lines = propertyFile.getLines()

				expect( lines[1].type ).toBe( 'comment' );
				expect( lines[2].type ).toBe( 'whitespace' );

				expect( lines[3].type ).toBe( 'property' );
				expect( lines[3].name ).toBe( 'brad' );
				expect( lines[3].value ).toBe( 'wood' );
				expect( lines[3].delimiter ).toBe( '=' );
				expect( propertyFile.get('brad') ).toBe( 'wood' );
				expect( propertyFile.brad ).toBe( 'wood' );


				expect( lines[11].type ).toBe( 'property' );
				expect( lines[11].name ).toBe( 'luis4' );
				expect( lines[11].value ).toBe( 'majano4' );
				expect( lines[11].delimiter ).toBe( ':' );
				expect( propertyFile.get('luis4') ).toBe( 'majano4' );
				expect( propertyFile.luis4 ).toBe( 'majano4' );

				expect( lines[20].type ).toBe( 'property' );
				expect( lines[20].name ).toBe( 'test' );
				expect( lines[20].value ).toBe( 'foobar' );
				expect( lines[20].delimiter ).toBe( ' ' );
				expect( propertyFile.get('test') ).toBe( 'foobar' );
				expect( propertyFile.test ).toBe( 'foobar' );
			} );

			it( "can handle basic escapes", () => {
				var propertyFile = new models.PropertyFile().load( expandPath( '/tests/resources/basic-escapes.properties' ) );
				var lines = propertyFile.getLines()

				expect( lines[1].type ).toBe( 'property' );
				expect( lines[1].name ).toBe( 'tabtest' );
				expect( lines[1].value ).toBe( 'foo#chr(9)#bar' );

				expect( lines[2].type ).toBe( 'property' );
				expect( lines[2].name ).toBe( 'newlinetest' );
				expect( lines[2].value ).toBe( 'foo#chr(10)#bar' );

				expect( lines[3].type ).toBe( 'property' );
				expect( lines[3].name ).toBe( 'backslashtest' );
				expect( lines[3].value ).toBe( 'foo\bar' );

				expect( lines[4].type ).toBe( 'property' );
				expect( lines[4].name ).toBe( 'quotetest' );
				expect( lines[4].value ).toBe( 'foo"bar' );

				expect( lines[5].type ).toBe( 'property' );
				expect( lines[5].name ).toBe( 'aposetest' );
				expect( lines[5].value ).toBe( "foo'bar" );

				expect( lines[6].type ).toBe( 'property' );
				expect( lines[6].name ).toBe( 'carriagereturntest' );
				expect( lines[6].value ).toBe( 'foo#chr(13)#bar' );

				expect( lines[7].type ).toBe( 'property' );
				expect( lines[7].name ).toBe( 'formfeedtest' );
				expect( lines[7].value ).toBe( 'foo#chr(12)#bar' );

				expect( lines[8].type ).toBe( 'property' );
				expect( lines[8].name ).toBe( 'unicode' );
				expect( lines[8].value ).toBe( 'foo#chr(8230)#bar' );

				expect( lines[9].type ).toBe( 'property' );
				expect( lines[9].name ).toBe( 'this is the name' );
				expect( lines[9].value ).toBe( 'something' );

				expect( lines[10].type ).toBe( 'property' );
				expect( lines[10].name ).toBe( 'C:' );
				expect( lines[10].value ).toBe( '/mnt/win' );

				expect( lines[11].type ).toBe( 'property' );
				expect( lines[11].name ).toBe( 'copyright' );
				expect( lines[11].value ).toBe( 'Copyright (c) 2003, Big Joe All rights reserved.' );

				expect( lines[12].type ).toBe( 'property' );
				expect( lines[12].name ).toBe( 'unneccessaryEscapes' );
				expect( lines[12].value ).toBe( 'I like spam' );

				expect( lines[13].type ).toBe( 'property' );
				expect( lines[13].name ).toBe( 'aNativeWindowsPath' );
				expect( lines[13].value ).toBe( 'C:\My Documents\test' );

				expect( lines[14].type ).toBe( 'property' );
				expect( lines[14].name ).toBe( 'someText' );
				expect( lines[14].value ).toBe( 'First line#chr(10)#Second line#chr(10)#Third line' );

				expect( lines[15].type ).toBe( 'property' );
				expect( lines[15].name ).toBe( 'copyright' );
				expect( lines[15].value ).toBe( 'Copyright (c) 2003, Big Joe All rights reserved.' );

			} );

			it( "can sync names", () => {
				var propertyFile = new models.PropertyFile();

				expect( propertyFile.exists( 'foo' ) ).toBe( false );
				expect( structKeyExists( propertyFile, 'foo' ) ).toBe( false );

				propertyFile.set( 'foo', 'bar' );
				expect( propertyFile.get( 'foo' ) ).toBe( 'bar' );
				expect( propertyFile.foo ).toBe( 'bar' );
				expect( propertyFile.exists( 'foo' ) ).toBe( true );

				propertyFile.remove( 'foo' );
				expect( propertyFile.exists( 'foo' ) ).toBe( false );
				expect( structKeyExists( propertyFile, 'foo' ) ).toBe( false );


				propertyFile.foo='bar' ;
				expect( propertyFile.get( 'foo' ) ).toBe( 'bar' );
				expect( propertyFile.foo ).toBe( 'bar' );
				expect( propertyFile.exists( 'foo' ) ).toBe( true );
			} );

			it( "can write property file", () => {
				var propertyFile = new models.PropertyFile().load( expandPath( '/tests/resources/test.properties' ) );

				propertyFile.store( expandPath( '/tests/tmp/test2.properties' ) )
				expect( fileReadNormalizedLF( expandPath( '/tests/tmp/test2.properties' ) ) ).toBe( fileReadNormalizedLF( expandPath( '/tests/resources/test.properties' ) ) );
			} );

			it( "can write novel property file", () => {
				var propertyFile = new models.PropertyFile();


				propertyFile.set( 'tabtest', 'foo#chr(9)#bar' );
				propertyFile.set( 'newlinetest', 'foo#chr(10)#bar' );
				propertyFile.set( 'backslashtest', 'foo\bar' );
				propertyFile.set( 'quotetest', 'foo"bar' );
				propertyFile.set( 'aposetest', "foo'bar" );
				propertyFile.set( 'carriagereturntest', 'foo#chr(13)#bar' );
				propertyFile.set( 'formfeedtest', 'foo#chr(12)#bar' );
				propertyFile.set( 'unicode', 'foo#chr(8230)#bar' );
				propertyFile.set( 'this is the name', 'something' );
				propertyFile.set( 'aNativeWindowsPath', 'C:\My Documents\test' );

				propertyFile.store( expandPath( '/tests/tmp/written.properties' ) )
				expect( fileReadNormalizedLF( expandPath( '/tests/tmp/written.properties' ) ) ).toBe( fileReadNormalizedLF( expandPath( '/tests/resources/written-standard.properties' ) ) );
			} );

			it( "can break lines", () => {
				var longString = repeatString( 'foo bar baz ', 50 );
				var propertyFile = new models.PropertyFile();
				propertyFile.long=longString;
				propertyFile.store( expandPath( '/tests/tmp/long.properties' ) );

				var propertyFile = new models.PropertyFile().load( expandPath( '/tests/tmp/long.properties' ) );
				expect( propertyFile.long ).toBe( longString );

			} );


		} );
	}

	function fileReadNormalizedLF( path ) {
		return fileRead( arguments.path )
			// turn CRLF into LF
			.replace( chr( 13 ) & chr( 10 ), chr( 10 ), 'all' )
			// turn CR into LF
			.replace( chr( 13 ), chr( 10 ), 'all' )
			// Remove trailing whitespace
			.trim();
	}
}