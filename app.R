


library(shiny)
library(dplyr)
library(knitr)
library(rmarkdown)
library(DT)
library(jsonlite)
library(hashids)


cat("Doing application setup\n")

onStop(function() {

  cat("Removing Temporary Files and Folders\n")
  unlink(temp_folder, recursive=TRUE)

})

temp_folder <<- file.path(tempdir(),
                          hashids::encode(as.integer(Sys.time()),
                                          hashid_settings(salt='fews', min_length = 6))
)

dir.create(temp_folder)

ui <- shinyUI(fluidRow(
  column(10,
        h2('Data Output'),
        DT::DTOutput("images"),
        downloadButton("report", "Generate report",
                       style="color: #fff; background-color: #337ab7; border-color: #2e6da4")
        )
  )
)

server <- shinyServer(function(input, output, session) {

    dat <- reactiveValues(images = data_frame("photographer" = c('A','B'),
                                              "organisation" = 'The Org',
                                              "location" = 'The Place',
                                              "address" = c('2 some place', '3 that place'))
    )

    output$images <- DT::renderDT(dat$images,
                                  server = FALSE,
                                  rownames = FALSE,
                                  class = 'dt-body nowrap',
                                  selection = 'single', editable = TRUE,
                                  extensions = c('Buttons','Responsive'),
                                  options = list(pageLength = 5,
                                                 dom = 'Blfrtip',
                                                 buttons = c('csv', 'excel')))

    output$report <- downloadHandler(

      filename = "Photo_Log.docx",
      content = function(file) {

        tempReport <<- file.path(temp_folder, "report.Rmd")
        tempTemplate <<- file.path(temp_folder, "photo_log_template.docx")
        file.copy("report.Rmd", tempReport, overwrite = TRUE)
        file.copy("photo_log_template.docx", tempTemplate, overwrite = TRUE)

        params <- list(organisation = input$select_org,
                       photographer = input$select_user,
                       df = select(dat$images,
                                   `Premises / Location` = location,
                                   Address = address)
                       )

        rmarkdown::render(tempReport, 'word_document',
                          output_file = file,
                          params = params,
                          envir = new.env(parent = globalenv())
        )
      }
    )

})

shinyApp(ui = ui, server = server)

