Pod::Spec.new do |s|

  s.name         = "Swift-LevelDB"
  s.version      = "1.0.0"
  s.summary      = "An Swift database library built over Google's LevelDB, a fast embedded key-value store written by Google."
  s.homepage     = "https://github.com/CoderYFL/Swift-LevelDB.git"
  s.license      = "MIT"
  s.author       = { "Cherish" => "390151825@qq.com" }
  s.platform     = :ios
  s.source       = { :git => "https://github.com/CoderYFL/Swift-LevelDB.git", :tag => "1.0.0" }
  s.source_files  = "Swift-LevelDB/Swift-leveldb/*.{swift,mm}"
  s.requires_arc = true

end