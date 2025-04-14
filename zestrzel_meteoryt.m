function zestrzel_meteoryt()
    %{
    funkcja zestrzel_meteoryt()
    Służy ona do symulacji przechwytu meteorytu, który uderza w naszą sferę
    chronioną.
    Po wywołaniu funkcji losowane są dane takie jak:
    - współrzędne początkowe meteorytu (x0, y0, z0)
    - kąty nachylenia do ziemii meteorytu (alpha, beta, gamma odpowiednio
    do osi x, y, z)
    - prędkość początkowa (v) meteorytu

    Następnie program sprawdza czy meteoryt uderzy w obszar chroniony
    Jeśli tak:
        Sprawdzi czy jesteśmy w stanie go przechwycić na bezpiecznej
        odległości (minimum 2km nad ziemią) zakładając, że rakieta jest
        wystrzelona z centrum obszaru chronionego:
        Jeśli tak:
            Program uruchomi symulacje zestrzelenia meteorytu
        Jeśli nie:
            Jesteśmy zgubieni
    Jeśli nie:
        Program zakończy działanie wraz ze stosownym komunikatem
    %}

    clc; close all;

    % Grawitacja (m/s^2):
    g = 9.81;

    % Promień chronionej przestrzeni powietrznej (w metrach):
    R = 200000;  % 200 km

    % Generowanie losowych danych meteorytu
    disp('=== DANE METEORYTU ===');

    % Losowe współrzędne początkowe (w km)
    x0 = (rand() * 400 - 200) * 1000;  % -200km do +200km
    y0 = (rand() * 400 - 200) * 1000;
    z0 = (rand() * 20 + 5) * 1000;     % 5km do 25km

    % Losowa prędkość (30-100 m/s)
    v_m = 30 + rand() * 70;

    % Losowe kąty (0-360 stopni)
    alpha_m = rand() * 360;
    beta_m = rand() * 360;
    gamma_m = rand() * 360;

    % Wyświetlanie wygenerowanych danych
    fprintf('Początkowa pozycja meteorytu:\n');
    fprintf('x0 = %.2f km\n', x0/1000);
    fprintf('y0 = %.2f km\n', y0/1000);
    fprintf('z0 = %.2f km\n', z0/1000);
    fprintf('Prędkość meteorytu: %.2f m/s\n', v_m);
    fprintf('Kąty meteorytu:\n');
    fprintf('alpha = %.2f°\n', alpha_m);
    fprintf('beta = %.2f°\n', beta_m);
    fprintf('gamma = %.2f°\n', gamma_m);

    % Przeliczenie kątów na radiany i wyznaczenie składowych prędkości:
    alpha_m_rad = deg2rad(alpha_m);
    beta_m_rad  = deg2rad(beta_m);
    gamma_m_rad = deg2rad(gamma_m);

    vx_m = v_m * cos(alpha_m_rad);
    vy_m = v_m * cos(beta_m_rad);
    vz_m = v_m * cos(gamma_m_rad);

    % ========================
    % 1) Tor ruchu meteorytu
    % ========================
    % Równania parametryczne (bez oporów powietrza):
    % x_m(t) = x0 + vx_m * t
    % y_m(t) = y0 + vy_m * t
    % z_m(t) = z0 + vz_m * t - 0.5*g*t^2

    % Znajdź czas uderzenia w ziemię (z=0). Rozwiązujemy:
    % z0 + vz_m*t - 0.5*g*t^2 = 0
    % A = -0.5*g, B = vz_m, C = z0

    A = -0.5*g;
    B = vz_m;
    C = z0;

    % Rozwiązanie równania kwadratowego A*t^2 + B*t + C = 0
    % t = [ -B +/- sqrt(B^2 - 4*A*C) ] / (2*A)
    discriminant = B^2 - 4*A*C;

    if discriminant < 0
        % Brak realnego czasu przecięcia z ziemią => meteoryt nie spada poniżej z=0
        % (być może wznosi się albo ma zbyt duży z0 i niewielką składową pionową).
        disp('Meteoryt nie uderzy w ziemię w rozpatrywanym modelu. Jesteśmy bezpieczni.');
        return;
    end

    t_ground_1 = (-B + sqrt(discriminant)) / (2*A);
    t_ground_2 = (-B - sqrt(discriminant)) / (2*A);

    % Interesuje nas dodatni czas:
    t_ground = max(t_ground_1, t_ground_2);
    if t_ground < 0
       % Oba czasy są ujemne -> w modelu matematycznym meteoryt "uderzył" w ziemię w przeszłości
       % albo nie uderzy w przyszłości.
       disp('Meteoryt nie uderzy w przyszłości w ziemię. Jesteśmy bezpieczni.');
       return;
    end

    % Współrzędne meteorytu w chwili uderzenia w ziemię:
    x_ground = x0 + vx_m * t_ground;
    y_ground = y0 + vy_m * t_ground;

    % Odległość od (0,0) w płaszczyźnie xy:
    dist_ground = sqrt(x_ground^2 + y_ground^2);

    % Sprawdzamy, czy uderzenie nastąpi w obrębie koła o promieniu R:
    if dist_ground > R
        disp('Meteoryt uderzy w ziemię poza chronionym obszarem. Jesteśmy bezpieczni.');
        pause(0.5);
        zestrzel_meteoryt();
        return;
    else
        disp('UWAGA: Meteoryt uderzy w ziemię w chronionym obszarze!');
        fprintf('Czas do uderzenia: %.2f s\n', t_ground);
    end

    % ================================================
    % 2) Wyznaczenie parametrów rakiety (przechwycenie)
    % ================================================
    % Rakietę wystrzeliwujemy z (0,0,0) w chwili t=0.
    % Chcemy ją skierować tak, by przechwyciła meteoryt jak najwcześniej,
    % ale na wysokości nie mniejszej niż 2 km.

    z_min = 2000;  % minimalna wysokość przechwytu (2 km)

    % Szukamy najwcześniejszego możliwego momentu przechwytu
    % Rozwiązujemy układ równań:
    % x0 + vx_m*t = vx_r*t
    % y0 + vy_m*t = vy_r*t
    % z0 + vz_m*t - 0.5*g*t^2 = vz_r*t - 0.5*g*t^2
    % z0 + vz_m*t - 0.5*g*t^2 >= z_min

    % Najpierw znajdźmy czas, w którym meteoryt osiągnie minimalną wysokość
    A_m = -0.5*g;
    B_m = vz_m;
    C_m = z0 - z_min;

    disc_m = B_m^2 - 4*A_m*C_m;
    if disc_m < 0
        disp('Meteoryt nie osiągnie wysokości 2 km (brak realnych rozwiązań).');
        disp('Niestety, nie jesteśmy w stanie go zestrzelić na bezpiecznej wysokości.');
        return;
    end

    t_min_1 = (-B_m + sqrt(disc_m)) / (2*A_m);
    t_min_2 = (-B_m - sqrt(disc_m)) / (2*A_m);

    % Interesują nas tylko dodatnie czasy i oczywiście krótszy z nich
    t_candidates = sort([t_min_1, t_min_2]);
    t_candidates = t_candidates(t_candidates>0);

    if isempty(t_candidates)
        disp('Czasy osiągnięcia minimalnej wysokości są ujemne, meteoryt był na tej wysokości w przeszłości.');
        disp('Rakieta nie ma możliwości przechwycenia.');
        return;
    end

    % Bierzemy najmniejszy dodatni czas:
    t_przechwyt = t_candidates(1);

    % Sprawdzamy czy przechwycenie nastąpi przed uderzeniem w ziemię
    if t_przechwyt >= t_ground
        disp('Meteoryt uderza w ziemię zanim osiągnie minimalną wysokość.');
        disp('Brak możliwości przechwycenia na bezpiecznej wysokości.');
        return;
    end

    % Pozycja meteorytu w chwili przechwycenia:
    x_m_intercept = x0 + vx_m * t_przechwyt;
    y_m_intercept = y0 + vy_m * t_przechwyt;
    z_m_intercept = z0 + vz_m * t_przechwyt - 0.5*g*t_przechwyt^2;

    % Obliczamy wymagane składowe prędkości rakiety
    vx_r = x_m_intercept / t_przechwyt;
    vy_r = y_m_intercept / t_przechwyt;
    vz_r = (z_m_intercept + 0.5*g*(t_przechwyt^2)) / t_przechwyt;

    % Całkowita prędkość rakiety:
    v_r = sqrt(vx_r^2 + vy_r^2 + vz_r^2);

    % Sprawdzenie czy prędkość rakiety nie przekracza 6.6 km/s
    % Zakładamy, że naszą rakietą jest rakieta wykorzystana w programie NASA DART, której V_max wynosi 6.6 km/s
    if v_r > 6600
        disp('UWAGA: Wymagana prędkość rakiety przekracza 6.6 km/s!');
        fprintf('Wymagana prędkość: %.2f m/s (%.2f km/s)\n', v_r, v_r/1000);
        disp('Program zatrzymany ze względów bezpieczeństwa.');
        return;
    end

    % Kąty rakiety względem osi x, y, z:
    alpha_r = acos(vx_r / v_r);
    beta_r  = acos(vy_r / v_r);
    gamma_r = acos(vz_r / v_r);

    % Konwersja na stopnie:
    alpha_r_deg = rad2deg(alpha_r);
    beta_r_deg  = rad2deg(beta_r);
    gamma_r_deg = rad2deg(gamma_r);

    % ======= WYŚWIETLANIE WYNIKÓW =======
    disp('=== WYNIKI PRZECHWYTU ===');
    fprintf('Czas przechwytu: t = %.2f s\n', t_przechwyt);
    fprintf('Pozycja przechwytu meteorytu: (%.2f, %.2f, %.2f) [m]\n',...
            x_m_intercept, y_m_intercept, z_m_intercept);
    fprintf('Pozycja uderzenia meteorytu: (%.2f, %.2f, 0) [m]\n',...
            x_ground, y_ground);
    fprintf('Niezbędna prędkość rakiety: v_r = %.2f m/s\n', v_r);
    fprintf('Kąty rakiety:\n');
    fprintf('   alpha_r względem osi x = %.2f stopni\n', alpha_r_deg);
    fprintf('   beta_r  względem osi y = %.2f stopni\n', beta_r_deg);
    fprintf('   gamma_r względem osi z = %.2f stopni\n', gamma_r_deg);

    % ==========================
    % 3) Wizualizacja trajektorii
    % ==========================

    % Aby ładnie narysować tor, weźmy pewną liczbę punktów czasowych
    % od 0 do max(t_ground, t_przechwyt) + pewien margines.
    t_max = max(t_ground, t_przechwyt);
    N = 200;  % liczba kroków
    t_vec = linspace(0, t_max, N);

    % Trajektoria meteorytu
    x_m_vec = x0 + vx_m.*t_vec;
    y_m_vec = y0 + vy_m.*t_vec;
    z_m_vec = z0 + vz_m.*t_vec - 0.5*g.*t_vec.^2;
    z_m_vec(z_m_vec<0) = 0;  % żeby nie rysować poniżej ziemi

    % Trajektoria rakiety
    x_r_vec = vx_r.*t_vec;
    y_r_vec = vy_r.*t_vec;
    z_r_vec = vz_r.*t_vec - 0.5*g.*t_vec.^2;
    z_r_vec(z_r_vec<0) = 0;  % też nie rysujemy poniżej ziemi

    figure('Name','Trajektorie meteorytu i rakiety','Color','white');

    % Subplot 1: 3D animacja
    subplot(1,2,1);
    plot3(x_m_vec, y_m_vec, z_m_vec, 'r','LineWidth',2); hold on;
    plot3(x_r_vec, y_r_vec, z_r_vec, 'b','LineWidth',2);
    plot3(x_m_intercept, y_m_intercept, z_min, 'ko','MarkerSize',8,'MarkerFaceColor','g');
    plot3(x_ground, y_ground, 0, 'ko','MarkerSize',8,'MarkerFaceColor','r');
    legend('Meteoryt','Rakieta','Punkt przechwytu','Punkt uderzenia','Location','best');
    xlabel('x [m]'); ylabel('y [m]'); zlabel('z [m]');
    grid on; axis tight;
    title('Trajektorie 3D');

    % Subplot 2: 2D rzut
    subplot(1,2,2);
    plot(x_m_vec, y_m_vec, 'r','LineWidth',2); hold on;
    plot(x_r_vec, y_r_vec, 'b','LineWidth',2);
    plot(x_m_intercept, y_m_intercept, 'ko','MarkerSize',8,'MarkerFaceColor','g');
    plot(x_ground, y_ground, 'ko','MarkerSize',8,'MarkerFaceColor','r');
    % Rysowanie chronionego obszaru
    theta = linspace(0, 2*pi, 100);
    plot(R*cos(theta), R*sin(theta), 'k--', 'LineWidth', 1);
    legend('Meteoryt','Rakieta','Punkt przechwytu','Punkt uderzenia','Chroniony obszar','Location','best');
    xlabel('x [m]'); ylabel('y [m]');
    grid on; axis equal;
    title('Rzut 2D trajektorii');

    % Animacja
    figure('Name','Animacja przechwytu','Color','white');

    % Ustawienie odpowiednich granic osi
    x_limits = [min([x_m_vec x_r_vec]) max([x_m_vec x_r_vec])];
    y_limits = [min([y_m_vec y_r_vec]) max([y_m_vec y_r_vec])];
    z_limits = [0 max([z_m_vec z_r_vec])];

    % Rysowanie tła
    plot3(x_m_vec, y_m_vec, z_m_vec, 'r:','LineWidth',1);
    hold on;
    plot3(x_r_vec, y_r_vec, z_r_vec, 'b:','LineWidth',1);
    plot3(x_m_intercept, y_m_intercept, z_min, 'ko','MarkerSize',8,'MarkerFaceColor','g');
    plot3(x_ground, y_ground, 0, 'ko','MarkerSize',8,'MarkerFaceColor','r');

    % Inicjalizacja obiektów animacji
    h_meteor = plot3(x_m_vec(1), y_m_vec(1), z_m_vec(1), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r', 'DisplayName', 'Meteoryt');
    h_rocket = plot3(x_r_vec(1), y_r_vec(1), z_r_vec(1), 'bo', 'MarkerSize', 10, 'MarkerFaceColor', 'b', 'DisplayName', 'Rakieta');

    % Konfiguracja wykresu
    xlabel('x [m]'); ylabel('y [m]'); zlabel('z [m]');
    grid on;
    axis([x_limits y_limits z_limits]);
    title('Animacja przechwytu');
    legend('Location','best');
    view(45, 30); % Ustawienie perspektywy 3D

    % Animacja
    try
        for i = 1:N
            % Sprawdź czy okno animacji nadal istnieje
            if ~isvalid(h_meteor) || ~isvalid(h_rocket)
                disp('Okno animacji zostało zamknięte.');
                break;
            end

            % Aktualizacja pozycji
            set(h_meteor, 'XData', x_m_vec(i), 'YData', y_m_vec(i), 'ZData', z_m_vec(i));
            set(h_rocket, 'XData', x_r_vec(i), 'YData', y_r_vec(i), 'ZData', z_r_vec(i));

            % Obliczenie odległości między rakietą a meteorytem
            distance = sqrt((x_m_vec(i) - x_r_vec(i))^2 + (y_m_vec(i) - y_r_vec(i))^2 + (z_m_vec(i) - z_r_vec(i))^2);

            % Sprawdzenie przechwytu
            if distance < 10
                disp('Przechwycenie meteorytu!');
                % Zaznaczenie momentu przechwytu
                plot3(x_m_vec(i), y_m_vec(i), z_m_vec(i), 'g*', 'MarkerSize', 20, 'LineWidth', 2);
                text(x_m_vec(i), y_m_vec(i), z_m_vec(i), '  Miejsce przechwytu', 'Color', 'g', 'FontWeight', 'bold');
                drawnow;
                break;
            end

            % Aktualizacja wykresu
            drawnow;
            pause(0.05);
        end

        % Dodaj komunikat sukcesu
        text(0.5, 0.5, 0.5, 'PRZECHWYT ZAKOŃCZONY SUKCESEM!', ...
            'Units', 'normalized', 'HorizontalAlignment', 'center', ...
            'FontSize', 14, 'FontWeight', 'bold', 'Color', 'g');

    catch ME
        if strcmp(ME.identifier, 'MATLAB:class:InvalidHandle')
            disp('Okno animacji zostało zamknięte.');
        else
            rethrow(ME);
        end
    end
end


% Masz ddosa
% Hello ur computer has virus