Pod::Spec.new do |spec|

spec.name         = "Swift-LevelDB"
spec.version      = "1.0.0"
spec.summary      = "An Swift database library built over Google's LevelDB, a fast embedded key-value store written by Google."
spec.homepage     = "https://github.com/CoderYFL/Swift-LevelDB.git"
spec.license      = "MIT"
spec.author       = { "Cherish" => "390151825@qq.com" }
spec.ios.deployment_target = "10.0"
spec.source       = { :git => "https://github.com/CoderYFL/Swift-LevelDB.git", :tag => "#{spec.version}" }
spec.source_files  = "Swift-LevelDB/Leveldb-library/*.{h,a}","Swift-LevelDB/Swift-leveldb/*.{h,mm,swift}",
spec.requires_arc = true

end
