# Uncomment this line to define a global platform for your project
# platform :ios, '9.0'

target 'TCC' do
  # Uncomment this line if you're using Swift or would like to use dynamic frameworks
  # use_frameworks!

  # Pods for TCC
  pod 'OpenCV', '~> 3.0.0'
end

post_install do |installer|
  installer.pods_project.build_configurations.each do |config|
      config.build_settings['GCC_OPTIMIZATION_LEVEL'] = '3'
  end
end
