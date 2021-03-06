require File.expand_path('../../../spec_helper', __FILE__)

module Pod
  describe AggregateTarget do
    describe 'In general' do
      before do
        @target_definition = Podfile::TargetDefinition.new('Pods', nil)
        @target_definition.link_with_first_target = true
        @target = AggregateTarget.new(@target_definition, config.sandbox)
      end

      it 'returns the target_definition that generated it' do
        @target.target_definition.should == @target_definition
      end

      it 'returns the label of the target definition' do
        @target.label.should == 'Pods'
      end

      it 'returns its name' do
        @target.name.should == 'Pods'
      end

      it 'returns the name of its product' do
        @target.product_name.should == 'libPods.a'
      end

      it 'returns the user targets' do
        project_path = SpecHelper.fixture('SampleProject/SampleProject.xcodeproj')
        @target.user_project_path = project_path
        @target.user_target_uuids = ['A346496C14F9BE9A0080D870']
        targets = @target.user_targets
        targets.count.should == 1
        targets.first.class.should == Xcodeproj::Project::PBXNativeTarget
      end
    end

    describe 'Support files' do
      before do
        @target_definition = Podfile::TargetDefinition.new('Pods', nil)
        @target_definition.link_with_first_target = true
        @target = AggregateTarget.new(@target_definition, config.sandbox)
        @target.client_root = config.sandbox.root.dirname
      end

      it 'returns the absolute path of the xcconfig file' do
        @target.xcconfig_path('Release').to_s.should.include?('Pods/Pods.release.xcconfig')
      end

      it 'returns the absolute path of the resources script' do
        @target.copy_resources_script_path.to_s.should.include?('Pods/Pods-resources.sh')
      end

      it 'returns the absolute path of the target header file' do
        @target.target_environment_header_path.to_s.should.include?('Pods/Pods-environment.h')
      end

      it 'returns the absolute path of the prefix header file' do
        @target.prefix_header_path.to_s.should.include?('Pods/Pods-prefix.pch')
      end

      it 'returns the absolute path of the bridge support file' do
        @target.bridge_support_path.to_s.should.include?('Pods/Pods.bridgesupport')
      end

      it 'returns the absolute path of the acknowledgements files without extension' do
        @target.acknowledgements_basepath.to_s.should.include?('Pods/Pods-acknowledgements')
      end

      it 'returns the path of the resources script relative to the user project' do
        @target.copy_resources_script_relative_path.should == '${SRCROOT}/Pods/Pods-resources.sh'
      end

      it 'returns the path of the xcconfig file relative to the user project' do
        @target.xcconfig_relative_path('Release').should == 'Pods/Pods.release.xcconfig'
      end
    end

    describe 'Pod targets' do
      before do
        @spec = fixture_spec('banana-lib/BananaLib.podspec')
        @target_definition = Podfile::TargetDefinition.new('Pods', nil)
        @pod_target = PodTarget.new([@spec], @target_definition, config.sandbox)
        @target = AggregateTarget.new(@target_definition, config.sandbox)
        @target.stubs(:platform).returns(:ios)
        @target.pod_targets = [@pod_target]
      end

      it 'returns pod targets by build configuration' do
        pod_target_release = PodTarget.new([@spec], @target_definition, config.sandbox)
        pod_target_release.expects(:include_in_build_config?).with('Debug').returns(false)
        pod_target_release.expects(:include_in_build_config?).with('Release').returns(true)
        @target.pod_targets = [@pod_target, pod_target_release]
        @target.user_build_configurations = {
          'Debug' => :debug,
          'Release' => :release,
        }
        expected = {
          'Debug' => @pod_target.specs,
          'Release' => (@pod_target.specs + pod_target_release.specs),
        }
        @target.specs_by_build_configuration.should == expected
      end

      it 'returns the specs of the Pods used by this aggregate target' do
        @target.specs.map(&:name).should == ['BananaLib']
      end

      it 'returns the specs of the Pods used by this aggregate target' do
        @target.specs.map(&:name).should == ['BananaLib']
      end

      it 'returns the spec consumers for the pod targets' do
        consumer_reps = @target.spec_consumers.map { |consumer| [consumer.spec.name, consumer.platform_name] }
        consumer_reps.should == [['BananaLib', :ios]]
      end
    end
  end
end
