# zestrzel_meteoryt
Program napisany w języku MATLAB w celach kursu Fizyka dla ISSP 2 na Wydziale Fizyki i Astronomii Uniwersytetu Wrocławskiego.
Służy on do symulowania systemu ochrony powietrznej, która w chronionym obszarze wystrzela rakietę mającą na celu zneutralizować zagrożenie z kosmosu.

## Metodyka
Program wykorzystuje proste obliczenie czasu zderzenia za pomocą funkcji kwadratowej <br> <br>
At^2+Bt+C = 0 <br>
Gdzie: <br>
A = -0.5*g (przyspieszenie ziemskie) <br>
B = v_z (prędkość meteorytu na osi z) <br>
C = z0 (położenie początkowe na osi z) <br> <br>

A następnie sprawdza czy rakieta o podanych parametrach jest w stanie w określonym czasie na określonej wysokości minimalnej zestrzelić meteoryt.

# Licencja
Repozytorium jest dostępne na licencji [CC BY-NC](https://creativecommons.org/licenses/by-nc/4.0/). 
