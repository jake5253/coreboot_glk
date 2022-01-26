<?php
$handle = popen("tail -f /workspace/coreboot_glk/logger/build.log", 'r');
while(!feof($handle)) {
    $buffer = fgets($handle);
    $lines_array = array_filter(preg_split('#[\r\n]+#', trim($buffer)));
        if(count($lines_array)){
            echo json_encode($lines_array);
        }
    ob_flush();
    flush();
}
pclose($handle);

/*session_start();

$file  = '/workspace/coreboot_glk/logger/build.log';

$total_lines = shell_exec('cat ' . escapeshellarg($file) . ' | wc -l');

if(isset($_SESSION['current_line']) && $_SESSION['current_line'] < $total_lines){

  $lines = shell_exec('tail -n' . ($total_lines - $_SESSION['current_line']) . ' ' . escapeshellarg($file));

} else if(!isset($_SESSION['current_line'])){

  $lines = shell_exec('tail -n100 ' . escapeshellarg($file));

}

$_SESSION['current_line'] = $total_lines;

$lines_array = array_filter(preg_split('#[\r\n]+#', trim($lines)));

if(count($lines_array)){
  echo json_encode(array($lines_array));
}

*/