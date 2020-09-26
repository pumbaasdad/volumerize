
cursor = db.test.find({"test": "test"});
while ( cursor.hasNext() ) {
   printjson( cursor.next() );
}
