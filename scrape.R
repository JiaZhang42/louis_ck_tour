library(gha)
library(tidyverse)
library(httr2)

# saleinfo_last <- 'initial value'
# saleinfo_last %>% write_rds('saleinfo_last.rds')
saleinfo_last <- readRDS("saleinfo_last.rds")

webpage <- 'https://louisck.com/pages/tickets'

# request the hidden API
api_url <- 'https://cdn.seated.com/api/tour/77b8f5ef-877c-470f-b5e6-e460d57359b2?include=tour-events'

res <- request(api_url) %>% 
  req_perform() %>% 
  resp_body_json() %>% 
  pluck('included')

res_tb <- res %>% 
  tibble(tb = .) %>% 
  unnest_wider(tb) %>% 
  unnest_wider(attributes)

saleinfo <- res_tb %>% 
  filter(`venue-name` == 'Hong Kong') %>% 
  pull(details)

if (length(saleinfo) == 0){
  stop("No sale information found! Did the website or the selector change?")
}


if(saleinfo != saleinfo_last){
  gha_notice("Sale Info updated. Sending notification.")
  msg <- "Click to see"
  request("https://ntfy.sh/") %>% 
    req_url_path('louis_ck_tour_hk') %>% 
    req_body_raw(msg) %>% 
    req_headers(Title = "HK Ticket Info Updated",
                Priority = "urgent",
                Tags = "loudspeaker,house", 
                Action = paste0('view, GO TO, ', webpage),
                Click = webpage) %>% 
    req_perform()
}

saleinfo %>% saveRDS("saleinfo_last.rds")

