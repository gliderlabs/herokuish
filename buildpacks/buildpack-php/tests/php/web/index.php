<?php

require '../vendor/autoload.php';

use Slim\Factory\AppFactory;
use Slim\Views\Twig;
use Slim\Views\TwigMiddleware;
use Monolog\Logger;
use Monolog\Handler\StreamHandler;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

$app = AppFactory::create();

$log = new Logger('app');
$log->pushHandler(new StreamHandler('php://stderr', Logger::DEBUG));

$twig = Twig::create(__DIR__ . '/views', ['cache' => false]);
$app->add(TwigMiddleware::create($app, $twig));

$app->get('/', function (Request $request, Response $response) use ($log) {
    $log->debug('logging output.');
    $response->getBody()->write('php');
    return $response;
});

$app->run();
