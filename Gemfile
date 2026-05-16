# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

gem "cocoapods", "1.16.2"
# Xcode 16+（object version 70）の Runner.xcodeproj を pod install が読めるようにする
gem "xcodeproj", github: "CocoaPods/Xcodeproj", ref: "2cf6a2263d2b164b87c1fdaed340667046b4e44d"
