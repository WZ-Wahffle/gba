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
    init_plugins(Plugin_To_Create.[.{name="Iprof"}, .{name="Autorun"}], *plugins, w);
    for plugins if it.init then it.init(it, .{});
    options := get_build_options();
    options.output_executable_name = "gba";
    options.output_path = "build";
    set_build_options(options, w);
    files := file_list("source");
    for files {
        add_build_file(it, w);
    }
    for plugins if it.add_source then it.add_source(it);
    for plugins if it.finish then it.finish(it);
    for plugins if it.shutdown then it.shutdown(it);
    set_build_options_dc(.{do_output=false});
}
