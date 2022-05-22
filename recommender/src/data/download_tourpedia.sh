#!/usr/bin/sh
# This script downloads all data from tourpedia and saves it to recommender/data/raw
output_dir="../../data/raw"
wget http://tour-pedia.org/download/amsterdam-accommodation.csv -P $output_dir
wget http://tour-pedia.org/download/barcelona-accommodation.csv -P $output_dir
wget http://tour-pedia.org/download/berlin-accommodation.csv -P $output_dir
wget http://tour-pedia.org/download/dubai-accommodation.csv -P $output_dir
wget http://tour-pedia.org/download/london-accommodation.csv -P $output_dir
wget http://tour-pedia.org/download/paris-accommodation.csv -P $output_dir
wget http://tour-pedia.org/download/rome-accommodation.csv -P $output_dir
wget http://tour-pedia.org/download/tuscany-accommodation.csv -P $output_dir
wget http://tour-pedia.org/download/amsterdam-restaurant.csv -P $output_dir
wget http://tour-pedia.org/download/barcelona-restaurant.csv -P $output_dir
wget http://tour-pedia.org/download/berlin-restaurant.csv -P $output_dir
wget http://tour-pedia.org/download/dubai-restaurant.csv -P $output_dir
wget http://tour-pedia.org/download/london-restaurant.csv -P $output_dir
wget http://tour-pedia.org/download/paris-restaurant.csv -P $output_dir
wget http://tour-pedia.org/download/rome-restaurant.csv -P $output_dir
wget http://tour-pedia.org/download/tuscany-restaurant.csv -P $output_dir
wget http://tour-pedia.org/download/amsterdam-poi.csv -P $output_dir
wget http://tour-pedia.org/download/barcelona-poi.csv -P $output_dir
wget http://tour-pedia.org/download/berlin-poi.csv -P $output_dir
wget http://tour-pedia.org/download/dubai-poi.csv -P $output_dir
wget http://tour-pedia.org/download/london-poi.csv -P $output_dir
wget http://tour-pedia.org/download/paris-poi.csv -P $output_dir
wget http://tour-pedia.org/download/rome-poi.csv -P $output_dir
wget http://tour-pedia.org/download/tuscany-poi.csv -P $output_dir
wget http://tour-pedia.org/download/amsterdam-attraction.csv -P $output_dir
wget http://tour-pedia.org/download/barcelona-attraction.csv -P $output_dir
wget http://tour-pedia.org/download/berlin-attraction.csv -P $output_dir
wget http://tour-pedia.org/download/dubai-attraction.csv -P $output_dir
wget http://tour-pedia.org/download/london-attraction.csv -P $output_dir
wget http://tour-pedia.org/download/paris-attraction.csv -P $output_dir
wget http://tour-pedia.org/download/rome-attraction.csv -P $output_dir
wget http://tour-pedia.org/download/tuscany-attraction.csv -P $output_dir
wget http://tour-pedia.org/download/tourpedia.rdf -P $output_dir