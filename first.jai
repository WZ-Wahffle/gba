#import "Compiler";
#import "File_Utilities";
#import "Process";
#import "Basic";

#run build_and_run();

build_and_run :: () {
    start_time := file_modtime_and_size("./build/gba");
    #run build();
    while true {
        modtime := file_modtime_and_size("./build/gba");
        if compare_apollo_times(start_time, modtime) != 0 break;
    }
    run_command("./build/gba");
}

build :: () {
    w := compiler_create_workspace();
    defer compiler_destroy_workspace(w);
    options := get_build_options();
    options.output_executable_name = "gba";
    options.output_path = "build";
    set_build_options(options, w);
    files := file_list("source");
    for files {
        add_build_file(it, w);
    }
    set_build_options_dc(.{do_output=false});
}
