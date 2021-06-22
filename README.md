## Introduction

An Swift database library built over [Google's LevelDB](http://code.google.com/p/leveldb), a fast embedded key-value store written by Google.

## Installation

By far, the easiest way to integrate this library in your project is by using [CocoaPods][1].

1. Have [Cocoapods][1] installed, if you don't already
2. In your Podfile, add the line 

        pod 'Swift-LevelDB'  //Unrealized

3. Run `pod install`
4. Make something awesome.

## How to use

#### Creating/Opening a database file on disk

```Swift
 let ldb = LevelDB.open(db: "share.db")
```

#### Close database

```Swift
 ldb.close()
```

##### Delete  database

```Swift
  ldb.deleteDatabaseFromDisk()
```

##### Cache data

```Swift
 ldb.put(key,value)
```

##### Delete data

```Swift
 ldb.delte("key")
```

##### Keys

```Swift
 let keys: [Slice] = ldb.keys()
```






