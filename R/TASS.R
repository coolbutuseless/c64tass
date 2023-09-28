


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Class wrapping the 64TASS assembler for easier testing of the R64 assembler
#'
#' Set `option(TASS_BIN=...)` and `option(X64_BIN=...)` to set the assembler
#' and emulator executable locations, or pass in as arguments
#' `TASS$new(tass_bin=..., x64_bin=...)`
#'
#' @examples
#' \dontrun{
#' tass <- TASS$new("./asm/border.asm", tass_bin = "~/bin/64tass", x64_bin = "~/bin/x64")
#' tass$dump_asm()
#' tass$compile()
#' tass$get_prg()
#' tass$get_asm()
#' tass$compile_and_run()
#' }
#'
#' @importFrom R6 R6Class
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
TASS <- R6::R6Class(
  "TASS",
  public = list(

    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #' @field asm the assembly code (as text)
    #' @field tass_bin location of TASS executable
    #' @field prg c64 PRG file with compiled 6502 machine code
    #' @field debug text output during compilation
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    asm      = NULL,
    tass_bin = NULL,
    prg      = NULL,
    debug    = NULL,


    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #' Initialise TASS
    #'
    #' @param asm the assembly code (as text) 
    #' @param tass_bin location of TASS executable
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    initialize = function(asm=NULL, tass_bin = getOption("TASS_BIN", '/opt/homebrew/bin/64tass')) {

      if (isTRUE(file.exists(asm))) {
        self$asm <- readLines(asm)
      } else {
        self$asm <- asm
      } 

      if (is.null(tass_bin)) {
        stop("No 'tass_bin' argument set. Please set full path to TASS executable")
      }
      if (!file.exists(tass_bin)) {
        stop("Could not find the specified TASS executable: ", tass_bin, "\nPlease set full path to the TASS executable on your system.")
      }
      self$tass_bin <- tass_bin 

      invisible(self)
    },


    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #' Compile asm with 64TASS
    #' 
    #' Note: Full TASS debugging output from the compilation step is kept
    #' in the variable \code{debug}.  Use \code{tass$get_debug()} to access
    #' 
    #' @param verbosity verboseness when compiling. 0 = no output, 
    #'        1 = messages from TASS compilation, 2 = all output from TASS
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    compile = function(verbosity = 1) {
      
      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      # Set up temporary files for compilation
      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      prg_filename <- tempfile(fileext = ".prg", pattern = "c64tass-")
      asm_filename <- tempfile(fileext = ".asm", pattern = "c64tass-")
      
      writeLines(self$asm, asm_filename)
      
      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      # Run compiler using 'system2()'
      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      args <- c("-C", "-a", "-i", asm_filename, "-o", prg_filename)
      self$debug <- system2(self$tass_bin, args, stdout = TRUE, stderr = TRUE)
      
      self$prg <- readBin(prg_filename, what='raw', n=file.size(prg_filename))

      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      # Show any messages
      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      if (verbosity > 1) {
        cat(self$debug, sep = "\n")
      } else if (verbosity > 0) {
        short_result <- grep("messages:", self$debug, value=TRUE)
        if (length(short_result) > 0) {
          cat(paste(short_result, collapse="\n"), "\n")
        }
      }
      
      self$debug <- paste0(self$debug, sep = "\n")
      
      invisible(self)
    },

    
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #' @description Get the ASM text
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    get_asm = function() {
      self$asm
    },
    
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #' @description  Get the compiled code as a raw vector
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    get_prg = function() {
      self$prg
    },
    
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #' @description Get the TASS debugging output from compilation
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    get_debug = function() {
      self$debug
    }
  )
)




#-------------------------------------------------------------------------------
# Testing
#-------------------------------------------------------------------------------
if (FALSE) {
  # options(TASS_BIN = "/opt/homebrew/bin/64tass")
  tass <- TASS$new("./inst/asm/border0.asm", "/usr/local/bin/64tass")
  tass$get_asm()
  tass$compile()
  tass$get_prg()
  tass$get_debug() |> cat()
}
