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
 let ldb = LevelDB.open(db: "share.db")
```

#### Close database

```Swift
 ldb.close()
```

#### Cache data

```Swift

let intValue: Int = 10
let cacheData = try? JSONEncoder().encode(intValue)
ldb.put("Int", value: cacheData)


if let getData = ldb.get("Int") {
   let getIntValue = try? JSONDecoder().decode(Int.self, from: getData)
   print(getIntValue ?? 0)
}

```
Remarks: The key type supports String and Data types

#### Delete data

```Swift
 ldb.delte("Int")
```


#### Keys

```Swift
 let keys: [Slice] = ldb.keys()
```


## License

Distributed under the [MIT license](LICENSE)

[1]: http://cocoapods.org
[2]: http://leveldb.googlecode.com/svn/trunk/doc/index.html



