<?php
/**
 * Created by PhpStorm.
 * User: x-vo
 * Date: 2/14/2018
 * Time: 17:17
 */

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\Controller;
use Symfony\Component\HttpFoundation\Response;

class CIController extends Controller
{
    public function index()
    {
        return new Response("php");
    }
}
