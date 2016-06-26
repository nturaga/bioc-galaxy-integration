planemo --help
# Simple R tool example
planemo bioc_tool_init --rscript ~/Documents/galaxyproject/bioc-galaxy-integration/my_r_tool/my_r_tool.R --example_command "Rscript my_r_tool.R --input input.csv --output output.csv"

# Multiple input output example
planemo nturaga (add_bioc_tool_init) $ planemo bioc_tool_init --rscript ~/Documents/galaxyproject/bioc-galaxy-integration/my_r_tool/my_r_tool_multi_inputs_outputs.R --example_command "Rscript my_r_tool_multi_inputs_outputs.R --input1 input1.csv --input2 input2.csv --output1 output1.csv --output2 output2.csv"

