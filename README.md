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

#### Open database

```Swift
 let ldb = LevelDB.open(db: "test.db")
```

#### Cache data

```Swift
let intValue: Int = 10
let cacheData = try? JSONEncoder().encode(intValue)
ldb.put("Int", value: cacheData)
```
Remarks: The key type supports String and Data types


#### Get data

```Swift
let getData = ldb.get("Int")
```


#### Delete data

```Swift
 ldb.delte("Int")
```


#### Keys

```Swift
 let keys: [Slice] = ldb.keys()
```

#### Close database

```Swift 
 ldb.close()
```


Remarks : The key type supports String and Data types

## License

Distributed under the [MIT license](LICENSE)

[1]: http://cocoapods.org
[2]: http://leveldb.googlecode.com/svn/trunk/doc/index.html



