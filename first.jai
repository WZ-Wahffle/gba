#import "Compiler";
#import "File_Utilities";
#import "Process";
#import "Basic";
#import "Metaprogram_Plugins";

#run,stallable build();

build :: () {
    w := compiler_create_workspace();
    defer compiler_destroy_workspace(w);
    plugins: [..]*Metaprogram_Plugin;
    // init_plugins(Plugin_To_Create.[.{name="Iprof"}], *plugins, w);
    for plugins if it.init then it.init(it, .{});
    options := get_build_options();
    options.output_executable_name = "gba";
    options.output_path = "build";
    options.llvm_options.output_llvm_ir = true;
    set_optimization(*options, .VERY_OPTIMIZED);
    set_build_options(options, w);
    i_flags: Intercept_Flags;
    for plugins if it.before_intercept then it.before_intercept(it, *i_flags);
    compiler_begin_intercept(w, i_flags);
    add_build_file("source/main.jai", w);
    for plugins if it.add_source then it.add_source(it);
    while true {
        message := compiler_wait_for_message();
        for plugins if it.message then it.message(it, message);
        if message.kind == {
            case .COMPLETE;
            break;
        }
    }
    compiler_end_intercept(w);
    for plugins if it.finish then it.finish(it);
    for plugins if it.shutdown then it.shutdown(it);
    set_build_options_dc(.{do_output=false});
}
